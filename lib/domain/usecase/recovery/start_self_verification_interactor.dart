import 'package:twake_chat/domain/app_state/recovery/self_verification_state.dart';
import 'package:twake_chat/utils/logging/sentry_tracked_events.dart';
import 'package:matrix/matrix.dart';

/// Starts a device-to-device (SAS) verification request against the
/// current user's own device keys, so this session can be verified from
/// another signed-in device.
class StartSelfVerificationInteractor {
  Future<SelfVerificationState> execute({required Client client}) async {
    try {
      await client.updateUserDeviceKeys();
      final deviceKeys = client.userDeviceKeys[client.userID];
      if (deviceKeys == null) {
        return SelfVerificationState.failure(
          exception: StateError('No device keys for current user'),
        );
      }
      final request = await deviceKeys.startVerification();
      return SelfVerificationState.started(request: request);
    } catch (e, s) {
      Logs().w(SentryTrackedEvents.unableToStartSelfVerification.message, e, s);
      return SelfVerificationState.failure(exception: e);
    }
  }
}
