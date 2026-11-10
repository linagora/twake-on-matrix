import 'package:twake_chat/data/drive/datasources_impl/sso_refresh_token_store.provider.dart';
import 'package:twake_chat/domain/drive/policy/drive_account_policy.provider.dart';
import 'package:twake_chat/domain/drive/usecases/resolve_drive_session_usecase.provider.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/sso_token_vault_provider.dart';

part 'drive_session_provider.g.dart';

/// The Drive session lives in memory only; its refresh token is the one part
/// kept across restarts, in `SsoRefreshTokenStore`. Separate from the Matrix
/// login on purpose: Matrix signs in through Synapse, which never hands this
/// app an id token.
@Riverpod(keepAlive: true)
class DriveSessionNotifier extends _$DriveSessionNotifier {
  Future<DriveSession>? _obtainFlight;
  Future<DriveSession>? _renewFlight;

  /// Replaced when the account changes, so a sign-in that was running for the
  /// previous account cannot store its result.
  _Turn _turn = _Turn();

  @override
  DriveSession? build() {
    ref.watch(activeUserIdProvider);
    _turn = _Turn();
    _obtainFlight = null;
    _renewFlight = null;
    return null;
  }

  /// Concurrent callers share one sign-in.
  ///
  /// Throws [DriveNotConfigured] when Drive is off, [DriveSessionSuperseded]
  /// when the account changed meanwhile, and the other [DriveException]s of
  /// `ResolveDriveSessionUseCase.execute`.
  Future<DriveSession> obtain() async {
    _requireEnabled();
    return _renewFlight ?? (_obtainFlight ??= _obtain(_turn));
  }

  /// For a token Drive refused. An in-flight obtain finishes first, so the
  /// refused token is not refreshed twice.
  Future<DriveSession> renew() async {
    _requireEnabled();
    return _renewFlight ??= _renew(_turn);
  }

  DriveIdToken? _held() {
    final held = state?.idToken;
    if (held != null) return held;
    final userId = ref.read(activeUserIdProvider);
    return userId == null ? null : ref.read(ssoTokenVaultProvider).of(userId);
  }

  /// A store that fails is read as nothing kept: the user signs in again.
  Future<DriveIdToken?> _stored(_Turn turn) async {
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return null;
    String? refreshToken;
    try {
      refreshToken = await ref
          .read(ssoRefreshTokenStoreProvider)
          .read(userId, issuer: ref.read(driveConfigProvider).ssoUrl);
    } on Exception {
      Logs().w('DriveSessionNotifier::_stored: the store failed');
    }
    if (!_isCurrent(turn)) throw const DriveSessionSuperseded();
    return refreshToken == null || refreshToken.isEmpty
        ? null
        : DriveIdToken.refreshOnly(refreshToken);
  }

  bool _isCurrent(_Turn turn) => ref.mounted && identical(turn, _turn);

  void _requireEnabled() {
    if (!ref.read(driveConfigProvider).isEnabled) {
      throw const DriveNotConfigured();
    }
  }

  Future<DriveSession> _obtain(_Turn turn) async {
    try {
      final current = _held() ?? await _stored(turn);
      return await _resolve(turn, current: current, refused: false);
    } finally {
      if (identical(turn, _turn)) _obtainFlight = null;
    }
  }

  Future<DriveSession> _renew(_Turn turn) async {
    try {
      final obtaining = _obtainFlight;
      if (obtaining != null) {
        try {
          await obtaining;
        } on DriveException {
          // The refused token still needs a fresh sign-in.
        }
      }
      if (!_isCurrent(turn)) throw const DriveSessionSuperseded();
      final current = _held() ?? await _stored(turn);
      return await _resolve(turn, current: current, refused: true);
    } finally {
      if (identical(turn, _turn)) _renewFlight = null;
    }
  }

  /// A store that fails does not fail the session: the next start signs in
  /// again.
  Future<void> _remember(
    _Owner owner,
    DriveSession session, {
    required DriveIdToken? known,
  }) async {
    final refreshToken = session.idToken.refreshToken;
    if (refreshToken == null || refreshToken == known?.refreshToken) return;
    try {
      await ref
          .read(ssoRefreshTokenStoreProvider)
          .write(owner.userId, refreshToken, issuer: owner.issuer);
    } on Exception {
      Logs().w('DriveSessionNotifier::_remember: the store failed');
    }
  }

  /// Drops what this account holds of another user's session, so the next use
  /// signs in again instead of refreshing it.
  Future<void> _forget(_Owner owner) async {
    ref.read(ssoTokenVaultProvider).remove(owner.userId);
    try {
      await ref.read(ssoRefreshTokenStoreProvider).delete(owner.userId);
    } on Exception {
      Logs().w('DriveSessionNotifier::_forget: the store failed');
    }
  }

  /// A session of someone else is neither used nor kept.
  bool _isOf(_Owner owner, DriveIdToken token) {
    final userId = owner.userId;
    final active = ref.read(activeMatrixClientProvider);
    final others = ref
        .read(accountClientsProvider)
        .where(
          (client) =>
              client.userID != userId &&
              client.homeserver?.origin == active?.homeserver?.origin,
        )
        .length;
    return ref
        .read(driveAccountPolicyProvider)
        .owns(
          token,
          localpart: userId.substring(1).split(':').first,
          otherAccountsOnServer: others,
        );
  }

  Future<DriveSession> _resolve(
    _Turn turn, {
    required DriveIdToken? current,
    required bool refused,
  }) async {
    // The SSO this sign-in talks to: the homeserver may change before it ends.
    final issuer = ref.read(driveConfigProvider).ssoUrl;
    final session = await ref
        .read(resolveDriveSessionUseCaseProvider)
        .execute(current: current, refused: refused);
    if (!_isCurrent(turn)) throw const DriveSessionSuperseded();
    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return state = session;
    final owner = _Owner(userId: userId, issuer: issuer);
    if (!_isOf(owner, session.idToken)) {
      Logs().w(
        'DriveSessionNotifier::_resolve: the SSO signed in another user',
      );
      await _forget(owner);
      throw const DriveSignInFailed(DriveSignInFailure.otherAccount);
    }
    state = session;
    ref.read(ssoTokenVaultProvider).remove(userId);
    await _remember(owner, session, known: current);
    return session;
  }
}

/// One account's run of the notifier, told apart by identity.
final class _Turn {}

/// The account a session is kept for, and the SSO that signed it in.
final class _Owner {
  const _Owner({required this.userId, required this.issuer});

  final String userId;
  final String issuer;
}
