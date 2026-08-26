import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/bootstrap/self_verification_state.dart';
import 'package:matrix/matrix.dart';

/// Starts a device-to-device (SAS) verification request against the
/// current user's own device keys, so this session can be verified from
/// another signed-in device.
class StartSelfVerificationInteractor {
  Stream<Either<Failure, Success>> execute({required Client client}) async* {
    yield const Right(StartSelfVerificationLoadingState());
    try {
      await client.updateUserDeviceKeys();
      final deviceKeys = client.userDeviceKeys[client.userID];
      if (deviceKeys == null) {
        yield Left(
          StartSelfVerificationFailureState(
            exception: StateError('No device keys for current user'),
          ),
        );
        return;
      }
      final request = await deviceKeys.startVerification();
      yield Right(StartSelfVerificationSuccessState(request: request));
    } catch (e, s) {
      Logs().w('Unable to start verification', e, s);
      yield Left(StartSelfVerificationFailureState(exception: e));
    }
  }
}
