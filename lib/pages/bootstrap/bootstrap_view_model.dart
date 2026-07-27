import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/app_state/bootstrap/cached_recovery_key_state.dart';
import 'package:fluffychat/domain/app_state/bootstrap/unlock_ssss_state.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_providers.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_state.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bootstrap_view_model.g.dart';

@riverpod
class BootstrapViewModel extends _$BootstrapViewModel {
  Bootstrap? _bootstrap;
  bool _constructing = false;
  bool _wipe = false;
  bool _isRetrying = false;
  bool _retryInFlight = false;

  /// `_start` always runs before anything else reads this, so it's safe to
  /// assume non-null past `build()`.
  Bootstrap get bootstrap => _bootstrap!;

  bool get supportsSecureStorage =>
      PlatformInfos.isMobile || PlatformInfos.isDesktop;

  @override
  BootstrapUiState build(Client client, {required bool wipe}) {
    ref.onDispose(() => _bootstrap?.onUpdate = null);
    _start(wipe);
    return _computeState();
  }

  void _start(bool wipe, {bool isRetry = false}) {
    // Detach the previous Bootstrap so its stale onUpdate can't fire.
    _bootstrap?.onUpdate = null;
    _wipe = wipe;
    _isRetrying = isRetry;
    // Bootstrap's constructor calls onUpdate synchronously before this
    // returns; _constructing makes that first call a no-op.
    _constructing = true;
    final created = client.encryption!.bootstrap(onUpdate: (_) => _refresh());
    _constructing = false;
    _bootstrap = created;
    if (isRetry) _prefillCachedRecoveryKey();
  }

  Future<void> _prefillCachedRecoveryKey() async {
    final userId = client.userID;
    if (userId == null) return;
    await for (final result
        in ref
            .read(readCachedRecoveryKeyInteractorProvider)
            .execute(userId: userId)) {
      if (!ref.mounted) return;
      result.fold((_) {}, (success) {
        if (success is CachedRecoveryKeyFoundState) {
          _cachedRecoveryKey = success.recoveryKey;
        }
      });
    }
  }

  String? _cachedRecoveryKey;

  void _refresh() {
    if (_constructing) return;
    state = _computeState();
  }

  BootstrapUiState _computeState() {
    final ssssKey = bootstrap.newSsssKey;
    if (ssssKey?.recoveryKey != null && !_recoveryKeyStored) {
      return BootstrapRecoveryKeyDisplayState(
        recoveryKey: ssssKey!.recoveryKey!,
        supportsSecureStorage: supportsSecureStorage,
      );
    }

    switch (bootstrap.state) {
      case BootstrapState.loading:
        return const BootstrapLoadingState();
      case BootstrapState.askWipeSsss:
        _driveNextFrame(() => bootstrap.wipeSsss(_wipe));
        return const BootstrapLoadingState();
      case BootstrapState.askBadSsss:
        _driveNextFrame(() => bootstrap.ignoreBadSecrets(true));
        return const BootstrapLoadingState();
      case BootstrapState.askUseExistingSsss:
        _driveNextFrame(() => bootstrap.useExistingSsss(!_wipe));
        return const BootstrapLoadingState();
      case BootstrapState.askUnlockSsss:
        _driveNextFrame(bootstrap.unlockedSsss);
        return const BootstrapLoadingState();
      case BootstrapState.askNewSsss:
        _driveNextFrame(bootstrap.newSsss);
        return const BootstrapLoadingState();
      case BootstrapState.openExistingSsss:
        if (_isRetrying && _retryOutcome == null) {
          _driveNextFrame(_autoRetryOpenExistingSsss);
        }
        return BootstrapVerifyDeviceState(
          prefilledRecoveryKey: _cachedRecoveryKey,
          retrySucceeded: _retryOutcome == true,
          retryFailed: _retryOutcome == false,
        );
      case BootstrapState.askWipeCrossSigning:
        _driveNextFrame(() => bootstrap.wipeCrossSigning(_wipe));
        return const BootstrapLoadingState();
      case BootstrapState.askSetupCrossSigning:
        _driveNextFrame(
          () => bootstrap.askSetupCrossSigning(
            setupMasterKey: true,
            setupSelfSigningKey: true,
            setupUserSigningKey: true,
          ),
        );
        return const BootstrapLoadingState();
      case BootstrapState.askWipeOnlineKeyBackup:
        _driveNextFrame(() => bootstrap.wipeOnlineKeyBackup(_wipe));
        return const BootstrapLoadingState();
      case BootstrapState.askSetupOnlineKeyBackup:
        _driveNextFrame(() => bootstrap.askSetupOnlineKeyBackup(true));
        return const BootstrapLoadingState();
      case BootstrapState.error:
        if (_isRetrying) {
          return BootstrapVerifyDeviceState(
            prefilledRecoveryKey: _cachedRecoveryKey,
            retryFailed: true,
          );
        }
        return const BootstrapLegacyErrorState();
      case BootstrapState.done:
        if (_isRetrying) {
          return BootstrapVerifyDeviceState(
            prefilledRecoveryKey: _cachedRecoveryKey,
            retrySucceeded: true,
          );
        }
        return const BootstrapLegacyDoneState();
    }
  }

  /// Auto-driven SDK transitions call straight back into `state =` (via
  /// [_refresh]) synchronously from inside `build()`/`_computeState()` in
  /// the original `StatefulWidget`, scheduled a frame later via
  /// `addPostFrameCallback` there only because it ran during `build()`.
  /// A Riverpod notifier isn't building a widget, so scheduling isn't
  /// required for correctness — kept as `Future.microtask` purely to avoid
  /// synchronously re-entering `state =` while the current `_computeState()`
  /// call is still resolving its return value.
  void _driveNextFrame(void Function() action) {
    Future.microtask(() {
      if (!ref.mounted) return;
      action();
    });
  }

  bool _recoveryKeyStored = false;
  bool? _retryOutcome;

  void setStoreInSecureStorage(bool value) {
    final current = state;
    if (current is! BootstrapRecoveryKeyDisplayState) return;
    state = current.copyWith(storeInSecureStorage: value);
  }

  Future<void> confirmRecoveryKeyCopied() async {
    final current = state;
    if (current is! BootstrapRecoveryKeyDisplayState) return;
    state = current.copyWith(recoveryKeyCopied: true);
  }

  /// Marks the recovery-key-display screen as handled and stores it in
  /// secure storage if the user opted in — mirrors the legacy "Next" button.
  Future<void> continueFromRecoveryKeyDisplay() async {
    final current = state;
    if (current is! BootstrapRecoveryKeyDisplayState) return;
    if (current.storeInSecureStorage) {
      final userId = client.userID;
      if (userId != null) {
        await for (final _
            in ref
                .read(storeRecoveryKeyInteractorProvider)
                .execute(userId: userId, recoveryKey: current.recoveryKey)) {}
      }
    }
    _recoveryKeyStored = true;
    _refresh();
  }

  Future<void> _autoRetryOpenExistingSsss() async {
    final recoveryKey = _cachedRecoveryKey;
    if (recoveryKey == null) {
      _retryOutcome = false;
      _retryInFlight = false;
      _refresh();
      return;
    }
    final success = await unlockWithRecoveryKey(recoveryKey);
    _retryOutcome = success;
    _retryInFlight = false;
    _refresh();
  }

  /// Unlocks SSSS with [recoveryKey], shared by the recovery-key form (via
  /// `VerifyDeviceViewModel`) and the automatic-retry path above.
  Future<bool> unlockWithRecoveryKey(String recoveryKey) async {
    Either<dynamic, dynamic>? last;
    await for (final result
        in ref
            .read(unlockSsssWithRecoveryKeyInteractorProvider)
            .execute(bootstrap: bootstrap, recoveryKey: recoveryKey)) {
      last = result;
    }
    return last?.fold((_) => false, (success) {
          return success is UnlockSsssSuccessState;
        }) ??
        false;
  }

  void retry() {
    if (_retryInFlight) return;
    _retryInFlight = true;
    _retryOutcome = null;
    _start(_wipe, isRetry: true);
    _refresh();
  }
}
