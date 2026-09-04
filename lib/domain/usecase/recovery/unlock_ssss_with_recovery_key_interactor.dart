import 'package:twake_chat/domain/app_state/recovery/unlock_ssss_state.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:twake_chat/utils/logging/sentry_tracked_events.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';

/// Unlocks the user's Secure Secret Storage and Sharing (SSSS) — the
/// Matrix spec's encrypted key/value store that backs up room keys and
/// cross-signing keys — using a previously generated recovery key, then
/// self-signs the current device via cross-signing.
class UnlockSsssWithRecoveryKeyInteractor {
  Future<UnlockSsssState> execute({
    required Bootstrap bootstrap,
    required String recoveryKey,
  }) async {
    try {
      // `newSsssKey` is the SSSS key handle the SDK exposes for the unlock
      // step; `encryption` drives cross-signing.
      final ssssKey = bootstrap.newSsssKey;
      final encryption = bootstrap.client.encryption;
      if (ssssKey == null || encryption == null) {
        return UnlockSsssState.failure(
          exception: Exception(
            'Cannot unlock SSSS: bootstrap is missing newSsssKey or '
            'client.encryption',
          ),
        );
      }
      await ssssKey.unlock(keyOrPassphrase: recoveryKey);
      Logs().d('SSSS unlocked');
      await encryption.crossSigning.selfSign(keyOrPassphrase: recoveryKey);
      Logs().d('Successful self-signed');
      await bootstrap.openExistingSsss();
      await KeychainSharingManager.saveRecoveryKey(
        userId: bootstrap.client.userID,
        recoveryKey: recoveryKey,
      );
      return const UnlockSsssState.success();
    } catch (e, s) {
      Logs().w(SentryTrackedEvents.unableToUnlockSsss.message, e, s);
      return UnlockSsssState.failure(exception: e);
    }
  }
}
