import 'package:twake_drive_picker/core.dart'
    show WorkplaceFilePickerConfigRequest;
import 'package:twake_drive_picker/ui.dart'
    show DriveIntentLoader, DrivePickerPlatform;

/// What the sheet needs to show Drive.
class DrivePickerRequest {
  const DrivePickerRequest({
    required this.intentLoader,
    required this.filePickerConfig,
    required this.platform,
  });

  final DriveIntentLoader intentLoader;
  final WorkplaceFilePickerConfigRequest filePickerConfig;
  final DrivePickerPlatform platform;
}

/// What the user sees when the picker cannot open.
enum DrivePickerProblem { signInFailed, chatAppMissing, couldNotOpen }

/// The answer of `DrivePickerController.prepare`.
sealed class DrivePickerPreparation {
  const DrivePickerPreparation();
}

final class DrivePickerReady extends DrivePickerPreparation {
  const DrivePickerReady(this.request, {required this.ticket});

  final DrivePickerRequest request;
  final int ticket;
}

/// Another pick is going on: do nothing.
final class DrivePickerBusy extends DrivePickerPreparation {
  const DrivePickerBusy();
}

/// The user backed out of the sign-in, or the account changed. Silent.
final class DrivePickerCancelled extends DrivePickerPreparation {
  const DrivePickerCancelled();
}

final class DrivePickerUnavailable extends DrivePickerPreparation {
  const DrivePickerUnavailable(this.problem);

  final DrivePickerProblem problem;
}
