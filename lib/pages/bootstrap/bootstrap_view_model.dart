import 'package:twake_chat/domain/app_state/recovery/cached_recovery_key_state.dart';
import 'package:twake_chat/domain/app_state/recovery/store_recovery_key_state.dart';
import 'package:twake_chat/domain/app_state/recovery/unlock_ssss_state.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_providers.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_state.dart';
import 'package:twake_chat/utils/platform_infos.dart';
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
    _recoveryKeyStored = false;
    // Bootstrap's constructor calls onUpdate synchronously before this
    // returns; _constructing makes that first call a no-op.
    _constructing = true;
    final created = client.encryption!.bootstrap(onUpdate: (_) => _refresh());
    _constructing = false;
    _bootstrap = created;
    if (isRetry) _cachedRecoveryKeyPrefill = _prefillCachedRecoveryKey();
  }

  Future<void>? _cachedRecoveryKeyPrefill;

  Future<void> _prefillCachedRecoveryKey() async {
    final userId = client.userID;
    if (userId == null) return;
    final result = await ref
        .read(readCachedRecoveryKeyInteractorProvider)
        .execute(userId: userId);
    if (!ref.mounted) return;
    if (result is CachedRecoveryKeyFoundState) {
      _cachedRecoveryKey = result.recoveryKey;
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
      case BootstrapState.openExistingSsss:
        return _computeOpenExistingSsssState();
      case BootstrapState.error:
        if (_isRetrying) {
          _retryInFlight = false;
          return BootstrapVerifyDeviceState(
            prefilledRecoveryKey: _cachedRecoveryKey,
            retryFailed: true,
          );
        }
        return const BootstrapLegacyErrorState();
      case BootstrapState.done:
        if (_isRetrying) {
          _retryInFlight = false;
          return BootstrapVerifyDeviceState(
            prefilledRecoveryKey: _cachedRecoveryKey,
            retrySucceeded: true,
          );
        }
        return const BootstrapLegacyDoneState();
      default:
        _driveAutoStep(bootstrap.state);
        return const BootstrapLoadingState();
    }
  }

  BootstrapUiState _computeOpenExistingSsssState() {
    // Unlocking with an existing key, not one the SDK just generated.
    _recoveryKeyStored = true;
    if (_isRetrying && _retryOutcome == null) {
      _driveNextFrame(_autoRetryOpenExistingSsss);
    }
    return BootstrapVerifyDeviceState(
      prefilledRecoveryKey: _cachedRecoveryKey,
      retrySucceeded: _retryOutcome == true,
      retryFailed: _retryOutcome == false,
    );
  }

  /// One auto-answer per `Bootstrap` question whose UI is just the loading
  /// spinner — each schedules its SDK call then waits for `onUpdate` to
  /// drive `_computeState()` again. Keyed by [BootstrapState] instead of a
  /// switch so dispatch in [_driveAutoStep] is a lookup, not a branch.
  late final Map<BootstrapState, void Function()> _autoStepActions = {
    BootstrapState.askWipeSsss: () => bootstrap.wipeSsss(_wipe),
    BootstrapState.askBadSsss: () => bootstrap.ignoreBadSecrets(true),
    BootstrapState.askUseExistingSsss: () => bootstrap.useExistingSsss(!_wipe),
    BootstrapState.askUnlockSsss: bootstrap.unlockedSsss,
    BootstrapState.askNewSsss: bootstrap.newSsss,
    BootstrapState.askWipeCrossSigning: () => bootstrap.wipeCrossSigning(_wipe),
    BootstrapState.askSetupCrossSigning: () => bootstrap.askSetupCrossSigning(
      setupMasterKey: true,
      setupSelfSigningKey: true,
      setupUserSigningKey: true,
    ),
    BootstrapState.askWipeOnlineKeyBackup: () =>
        bootstrap.wipeOnlineKeyBackup(_wipe),
    BootstrapState.askSetupOnlineKeyBackup: () =>
        bootstrap.askSetupOnlineKeyBackup(true),
  };

  void _driveAutoStep(BootstrapState step) {
    final action = _autoStepActions[step];
    if (action != null) _driveNextFrame(action);
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
  ///
  /// A failed cache write is logged (via Sentry) but doesn't block the
  /// flow: the user has already seen and copied the key, so trapping them
  /// on this screen would be worse than proceeding without the cache.
  Future<void> continueFromRecoveryKeyDisplay() async {
    final current = state;
    if (current is! BootstrapRecoveryKeyDisplayState) return;
    if (current.storeInSecureStorage) {
      final userId = client.userID;
      if (userId != null) {
        final result = await ref
            .read(storeRecoveryKeyInteractorProvider)
            .execute(userId: userId, recoveryKey: current.recoveryKey);
        if (!ref.mounted) return;
        if (result is StoreRecoveryKeyFailureState) {
          Logs().w(
            'continueFromRecoveryKeyDisplay: recovery key not cached',
            result.exception,
          );
        }
      }
    }
    _recoveryKeyStored = true;
    _refresh();
  }

  Future<void> _autoRetryOpenExistingSsss() async {
    await _cachedRecoveryKeyPrefill;
    if (!ref.mounted) return;
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
    final result = await ref
        .read(unlockSsssWithRecoveryKeyInteractorProvider)
        .execute(bootstrap: bootstrap, recoveryKey: recoveryKey);
    return result is UnlockSsssSuccessState;
  }

  void retry() {
    if (_retryInFlight) return;
    _retryInFlight = true;
    _retryOutcome = null;
    _start(_wipe, isRetry: true);
    _refresh();
  }
}
