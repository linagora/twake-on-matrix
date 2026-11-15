import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/drive/policy/drive_platform_url_policy.dart';
import 'package:twake_chat/domain/drive/policy/id_token_expiry_policy.dart';
import 'package:twake_chat/domain/drive/sources/twake_sso_source.dart';

class ResolveDriveSessionUseCase {
  const ResolveDriveSessionUseCase({
    required TwakeSsoSource ssoSource,
    required DrivePlatformUrlPolicy urlPolicy,
    required IdTokenExpiryPolicy expiryPolicy,
    required DateTime Function() now,
  }) : _ssoSource = ssoSource,
       _urlPolicy = urlPolicy,
       _expiryPolicy = expiryPolicy,
       _now = now;

  final TwakeSsoSource _ssoSource;
  final DrivePlatformUrlPolicy _urlPolicy;
  final IdTokenExpiryPolicy _expiryPolicy;
  final DateTime Function() _now;

  /// Returns a session whose token is usable: [current] when it still is,
  /// else a new one. The caller keeps the session.
  ///
  /// A new token comes from the refresh token of [current] (no browser) and,
  /// when there is none or the SSO refuses it, from a sign-in. [refused] says
  /// Drive turned [current] down, so it is not reused even if it has not
  /// expired.
  ///
  /// Throws the [DriveException]s of [TwakeSsoSource.signIn] and of
  /// [DrivePlatformUrlPolicy.resolve], and the network ones of
  /// [TwakeSsoSource.refresh].
  Future<DriveSession> execute({
    DriveIdToken? current,
    bool refused = false,
  }) async {
    final held = current;
    final DriveIdToken token;
    if (held != null && _reusable(held, refused: refused)) {
      token = held;
    } else {
      token = await _renewed(held) ?? await _signedIn();
    }
    return DriveSession(idToken: token, platformUrl: _urlPolicy.resolve(token));
  }

  /// A new sign-in whose token the policy accepts: one that would expire before
  /// Drive uses it is refused, not retried.
  Future<DriveIdToken> _signedIn() async {
    final token = await _ssoSource.signIn();
    if (!_expiryPolicy.isUsable(token, _now())) {
      throw const DriveSignInFailed(DriveSignInFailure.invalidIdToken);
    }
    return token;
  }

  bool _reusable(DriveIdToken held, {required bool refused}) =>
      !refused && _expiryPolicy.isUsable(held, _now());

  /// A refreshed token, or null when [held] cannot be refreshed: it has no
  /// refresh token, or the SSO refuses it and only the browser can help.
  Future<DriveIdToken?> _renewed(DriveIdToken? held) async {
    final refreshToken = held?.refreshToken;
    if (refreshToken == null) return null;
    try {
      final token = await _ssoSource.refresh(refreshToken);
      // A refreshed token that the policy refuses is no better than a refused
      // refresh: the browser gets a new one.
      return _expiryPolicy.isUsable(token, _now()) ? token : null;
    } on DriveSignInFailed {
      return null;
    }
  }
}
