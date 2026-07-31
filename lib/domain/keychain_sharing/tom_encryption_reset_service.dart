import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:fluffychat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:fluffychat/domain/usecase/recovery/save_recovery_words_interactor.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

/// Outcome of [TomEncryptionResetService.reset], distinguishing *why* it
/// failed so the caller can show a message that matches the failed step —
/// mirrors the distinct error states [TomBootstrapDialog] handles
/// (`wipeRecoveryFailed`, `unlockError`/`uploadError`, `BootstrapState.error`).
enum TomEncryptionResetResult {
  success,

  /// Deleting the old recovery words from the ToM vault failed.
  wipeFailed,

  /// Uploading the newly generated recovery key to the ToM vault failed.
  uploadFailed,

  /// Any other step (generating the new SSSS key, cross-signing, key
  /// backup) failed.
  bootstrapFailed,
}

/// Runs the same wipe-and-recreate SSSS/cross-signing/key-backup sequence as
/// [TomBootstrapDialog]'s `wipeRecovery` path, but headless — no widget, no
/// dialog shown. Used by the "Not possible to verify?" reset button so the
/// caller can drive its own inline loading UI instead of a second dialog
/// popping up over the first, and only finish loading once this completes.
class TomEncryptionResetService {
  final Client client;

  TomEncryptionResetService({required this.client});

  final _deleteRecoveryWordsInteractor = getIt
      .get<DeleteRecoveryWordsInteractor>();
  final _getRecoveryWordsInteractor = getIt.get<GetRecoveryWordsInteractor>();
  final _saveRecoveryWordsInteractor = getIt.get<SaveRecoveryWordsInteractor>();

  Future<RecoveryWords?> _getRecoveryWords() async {
    final result = await _getRecoveryWordsInteractor.execute();
    return result.fold((failure) => null, (success) => success.words);
  }

  /// Deletes the old recovery words from the ToM vault, generates a brand
  /// new SSSS/cross-signing/key-backup set locally, and uploads the new
  /// recovery key — resolves to [TomEncryptionResetResult.success] only once
  /// everything has completed.
  Future<TomEncryptionResetResult> reset() async {
    final deleted = await _deleteRecoveryWordsInteractor.execute();
    final deleteFailed = deleted.fold((failure) => true, (success) => false);
    if (deleteFailed) {
      Logs().w('TomEncryptionResetService::reset(): wipe recoveryWords failed');
      return TomEncryptionResetResult.wipeFailed;
    }

    final bootstrap = client.encryption!.bootstrap();
    final oldRecoveryWords = await _getRecoveryWords();

    try {
      await _driveBootstrapToNewKey(bootstrap, wipe: true);
    } catch (e, s) {
      Logs().w('TomEncryptionResetService::reset(): bootstrap failed', e, s);
      return TomEncryptionResetResult.bootstrapFailed;
    }

    final newKey = bootstrap.newSsssKey?.recoveryKey;
    if (newKey == null) {
      Logs().w('TomEncryptionResetService::reset(): no new recovery key');
      return TomEncryptionResetResult.bootstrapFailed;
    }
    await KeychainSharingManager.saveRecoveryKey(
      userId: client.userID,
      recoveryKey: newKey,
    );

    // Only re-upload if the vault doesn't already hold this exact key —
    // mirrors TomBootstrapDialog's `_existedRecoveryWordsInTom` check.
    if (oldRecoveryWords?.words != newKey) {
      final uploaded = await _saveRecoveryWordsInteractor.execute(newKey);
      final uploadFailed = uploaded.fold((failure) => true, (success) => false);
      if (uploadFailed) {
        Logs().w('TomEncryptionResetService::reset(): upload key failed');
        return TomEncryptionResetResult.uploadFailed;
      }
    }

    final done = await _driveBootstrapToDone(bootstrap, wipe: true);
    return done
        ? TomEncryptionResetResult.success
        : TomEncryptionResetResult.bootstrapFailed;
  }

  /// Drives [bootstrap] through askWipeSsss → askNewSsss → newSsss, i.e. up
  /// to (and including) generating the new SSSS key — same states
  /// TomBootstrapDialog walks through before reaching `created`.
  Future<void> _driveBootstrapToNewKey(
    Bootstrap bootstrap, {
    required bool wipe,
  }) async {
    while (bootstrap.state != BootstrapState.askNewSsss) {
      _advancePreKeyState(bootstrap, wipe: wipe);
    }
    await bootstrap.newSsss();
    if (bootstrap.state == BootstrapState.error) {
      throw BootstrapBadStateException('newSsss() failed');
    }
  }

  /// Advances [bootstrap] one step through the states leading up to
  /// `askNewSsss` (wiping or reusing an existing SSSS key).
  void _advancePreKeyState(Bootstrap bootstrap, {required bool wipe}) {
    switch (bootstrap.state) {
      case BootstrapState.askWipeSsss:
        bootstrap.wipeSsss(wipe);
      case BootstrapState.askBadSsss:
        bootstrap.ignoreBadSecrets(true);
      case BootstrapState.askUseExistingSsss:
        bootstrap.useExistingSsss(!wipe);
      case BootstrapState.askUnlockSsss:
        bootstrap.unlockedSsss();
      case BootstrapState.error:
        throw BootstrapBadStateException('Bootstrap reached error state');
      default:
        throw BootstrapBadStateException(
          'Unexpected bootstrap state ${bootstrap.state}',
        );
    }
  }

  /// Drives [bootstrap] from `created` (new key already generated) through
  /// cross-signing and key-backup setup to `done`, same as
  /// TomBootstrapDialog's `_handleBootstrapState` for those states.
  Future<bool> _driveBootstrapToDone(
    Bootstrap bootstrap, {
    required bool wipe,
  }) async {
    while (bootstrap.state != BootstrapState.done) {
      switch (bootstrap.state) {
        case BootstrapState.askWipeCrossSigning:
          await bootstrap.wipeCrossSigning(wipe);
        case BootstrapState.askSetupCrossSigning:
          await bootstrap.askSetupCrossSigning(
            setupMasterKey: true,
            setupSelfSigningKey: true,
            setupUserSigningKey: true,
          );
        case BootstrapState.askWipeOnlineKeyBackup:
          bootstrap.wipeOnlineKeyBackup(wipe);
        case BootstrapState.askSetupOnlineKeyBackup:
          await bootstrap.askSetupOnlineKeyBackup(true);
        case BootstrapState.error:
          return false;
        default:
          return false;
      }
    }
    return true;
  }
}
