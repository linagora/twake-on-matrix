import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/drive/entities/drive_picked_file.dart';

part 'drive_pick_plan.freezed.dart';

/// What a pick asks the chat to do: send [links], or download and attach
/// [downloads]. Never both: the user pressed one button in Drive.
@freezed
abstract class DrivePickPlan with _$DrivePickPlan {
  const factory DrivePickPlan({
    @Default([]) List<DrivePickedFile> links,
    @Default([]) List<DrivePickedFile> downloads,

    /// Shortcuts (a `.url` file) the user picked to attach: their bytes are a
    /// link, never a file to send.
    @Default(0) int skippedShortcuts,
  }) = _DrivePickPlan;
}
