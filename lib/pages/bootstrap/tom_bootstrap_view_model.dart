import 'package:fluffychat/di/global/dio_cache_interceptor_for_client.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:fluffychat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/save_recovery_words_interactor.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_state.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tom_bootstrap_view_model.g.dart';

@riverpod
class TomBootstrapViewModel extends _$TomBootstrapViewModel {
  static const noRecoveryWordsCloseDelay = Duration(seconds: 5);

  final _saveRecoveryWordsInteractor = getIt.get<SaveRecoveryWordsInteractor>();
  final _getRecoveryWordsInteractor = getIt.get<GetRecoveryWordsInteractor>();
  final _deleteRecoveryWordsInteractor = getIt
      .get<DeleteRecoveryWordsInteractor>();

  Bootstrap? _bootstrap;
  bool _wipe = false;
  RecoveryWords? _recoveryWords;
  int _popTick = 0;

  @override
  TomBootstrapUiState build(
    Client client, {
    required bool wipe,
    required bool wipeRecovery,
    required bool twakeSupported,
  }) {
    _wipe = wipe;
    if (client.userID != null) {
      DioCacheInterceptorForClient(client.userID!).setup(getIt);
    }
    _loadInitialData(
      wipeRecovery: wipeRecovery,
      twakeSupported: twakeSupported,
    );
    return const TomBootstrapLoadingState();
  }

  /// Every terminal state goes through here with a freshly bumped
  /// [_popTick], so `ref.listen` in the widget always observes a change —
  /// two terminal states of the same subtype would otherwise compare equal
  /// via [Equatable] and Riverpod would skip the notification, silently
  /// dropping the pop/snackbar side effect.
  void _refresh(TomBootstrapUiState Function({int popTick}) build) {
    if (!ref.mounted) return;
    _popTick++;
    state = build(popTick: _popTick);
  }

  Future<void> _loadInitialData({
    required bool wipeRecovery,
    required bool twakeSupported,
  }) async {
    await client.firstSyncReceived;
    await client.userDeviceKeysLoading;
    await client.roomsLoading;
    await client.accountDataLoading;

    if (wipeRecovery) {
      await _wipeRecoveryWord(twakeSupported: twakeSupported);
      return;
    }
    _refresh(TomBootstrapCheckingRecoveryState.new);
    await _resolveRecoveryKeyState();
  }

  Future<RecoveryWords?> _getRecoveryWords() async {
    final result = await _getRecoveryWordsInteractor.execute();
    return result.fold((failure) => null, (success) => success.words);
  }

  void _createBootstrap() {
    _bootstrap = client.encryption?.bootstrap(
      onUpdate: (_) => _handleBootstrapState(),
    );
  }

  Future<void> _resolveRecoveryKeyState() async {
    await client.onSync.stream.first;

    if (client.encryption?.keyManager.enabled == true) {
      final needsRecovery =
          await client.encryption?.keyManager.isCached() == false ||
          await client.encryption?.crossSigning.isCached() == false ||
          client.isUnknownSession;
      if (!needsRecovery) return;

      final recoveryWords = await _getRecoveryWords();
      _createBootstrap();
      if (recoveryWords != null) {
        _recoveryWords = recoveryWords;
        _handleBootstrapState();
        return;
      }
      // No recovery words to fall back on — nothing to show, just wait the
      // same pause the original gave the user before closing (pop false).
      _refresh(TomBootstrapNoRecoveryWordsState.new);
      Future.delayed(noRecoveryWordsCloseDelay, () {
        if (!ref.mounted) return;
        _refresh(
          ({popTick = 0}) => TomBootstrapNoRecoveryWordsState(
            popTick: popTick,
            popValue: false,
          ),
        );
      });
      return;
    }

    final recoveryWords = await _getRecoveryWords();
    _createBootstrap();
    _wipe = recoveryWords != null;
    _recoveryWords = recoveryWords;
    _handleBootstrapState();
  }

  bool _existedRecoveryWordsInTom(String? key) {
    if (key == null && _recoveryWords != null) return true;
    return _recoveryWords != null && _recoveryWords!.words == key;
  }

  void _handleBootstrapState() {
    final bootstrap = _bootstrap;
    if (bootstrap == null) return;
    switch (bootstrap.state) {
      case BootstrapState.askNewSsss:
        bootstrap.newSsss().then((_) => _handleNewRecoveryKeyCreated());
      case BootstrapState.openExistingSsss:
        _unlockBackUp();
      case BootstrapState.error:
        _refresh(TomBootstrapErrorState.new);
      case BootstrapState.done:
        _refresh(TomBootstrapDoneState.new);
      default:
        _driveAutoStep(bootstrap);
    }
  }

  /// Advances every `Bootstrap` state that just answers the SDK's next
  /// question (optionally after a UI-visible `_refresh`) and waits for its
  /// `onUpdate` callback to drive `_handleBootstrapState()` again.
  void _driveAutoStep(Bootstrap bootstrap) {
    switch (bootstrap.state) {
      case BootstrapState.loading:
        _refresh(TomBootstrapLoadingState.new);
      case BootstrapState.askWipeSsss:
        bootstrap.wipeSsss(_wipe);
      case BootstrapState.askBadSsss:
        bootstrap.ignoreBadSecrets(true);
      case BootstrapState.askUseExistingSsss:
        bootstrap.useExistingSsss(!_wipe);
      case BootstrapState.askUnlockSsss:
        bootstrap.unlockedSsss();
      case BootstrapState.askWipeCrossSigning:
        bootstrap.wipeCrossSigning(_wipe);
      case BootstrapState.askSetupCrossSigning:
        _refresh(TomBootstrapUploadingCrossSigningKeysState.new);
        bootstrap.askSetupCrossSigning(
          setupMasterKey: true,
          setupSelfSigningKey: true,
          setupUserSigningKey: true,
        );
      case BootstrapState.askWipeOnlineKeyBackup:
        bootstrap.wipeOnlineKeyBackup(_wipe);
      case BootstrapState.askSetupOnlineKeyBackup:
        bootstrap.askSetupOnlineKeyBackup(true);
      case BootstrapState.askNewSsss:
      case BootstrapState.openExistingSsss:
      case BootstrapState.error:
      case BootstrapState.done:
        break;
    }
  }

  Future<void> _handleNewRecoveryKeyCreated() async {
    final key = _bootstrap?.newSsssKey?.recoveryKey;
    if (key == null) return;
    await KeychainSharingManager.saveRecoveryKey(
      userId: client.userID,
      recoveryKey: key,
    );
    if (_existedRecoveryWordsInTom(key)) {
      // Already backed up under this exact key — continue the SDK state
      // machine instead of re-uploading.
      _handleBootstrapState();
      return;
    }
    await _backUpInRecoveryVault(key);
  }

  Future<void> _backUpInRecoveryVault(String key) async {
    final either = await _saveRecoveryWordsInteractor.execute(key);
    either.fold(
      (failure) => _refresh(TomBootstrapUploadErrorState.new),
      (success) => _handleBootstrapState(),
    );
  }

  Future<void> _unlockBackUp() async {
    final recoveryWords = _recoveryWords;
    if (recoveryWords == null) {
      _refresh(TomBootstrapUnlockErrorState.new);
      return;
    }
    try {
      await _bootstrap?.newSsssKey!.unlock(
        keyOrPassphrase: recoveryWords.words,
      );
      await _bootstrap?.client.encryption!.crossSigning.selfSign(
        keyOrPassphrase: recoveryWords.words,
      );
      await _bootstrap?.openExistingSsss();
      await KeychainSharingManager.saveRecoveryKey(
        userId: client.userID,
        recoveryKey: recoveryWords.words,
      );
      _handleBootstrapState();
    } catch (e, s) {
      Logs().w(
        'TomBootstrapViewModel::_unlockBackUp() Unable to unlock SSSS',
        e,
        s,
      );
      _refresh(TomBootstrapUnlockErrorState.new);
    }
  }

  Future<void> _wipeRecoveryWord({required bool twakeSupported}) async {
    final either = await _deleteRecoveryWordsInteractor.execute();
    _createBootstrap();
    either.fold((failure) {
      if (twakeSupported) {
        _refresh(TomBootstrapWipeRecoveryFailedState.new);
      } else {
        // Original fell through to a plain spinner (no TOM support means
        // no snackbar/pop) and let the next `bootstrap.onUpdate` tick
        // carry the flow forward on its own.
        _refresh(TomBootstrapCheckingRecoveryState.new);
      }
    }, (success) => _handleBootstrapState());
  }
}
