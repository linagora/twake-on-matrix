import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/bootstrap/unlock_ssss_state.dart';
import 'package:fluffychat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';

class UnlockSsssWithRecoveryKeyInteractor {
  Stream<Either<Failure, Success>> execute({
    required Bootstrap bootstrap,
    required String recoveryKey,
  }) async* {
    yield const Right(UnlockSsssLoadingState());
    try {
      final ssssKey = bootstrap.newSsssKey;
      final encryption = bootstrap.client.encryption;
      if (ssssKey == null || encryption == null) {
        yield Left(
          UnlockSsssFailureState(
            exception: Exception(
              'Cannot unlock SSSS: bootstrap is missing newSsssKey or '
              'client.encryption',
            ),
          ),
        );
        return;
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
      yield const Right(UnlockSsssSuccessState());
    } catch (e, s) {
      Logs().w('Unable to unlock SSSS', e, s);
      yield Left(UnlockSsssFailureState(exception: e));
    }
  }
}
