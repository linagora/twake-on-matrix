import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_picker_state.freezed.dart';

/// Where the picker is. One at a time: a second tap while it is not [idle] does
/// nothing.
@freezed
sealed class DrivePickerState with _$DrivePickerState {
  const factory DrivePickerState.idle() = DrivePickerIdle;

  /// Waiting for the Twake SSO (the browser) and the session.
  const factory DrivePickerState.signingIn(int ticket) = DrivePickerSigningIn;

  /// The sheet with Drive is on screen.
  const factory DrivePickerState.open(int ticket) = DrivePickerOpen;
}
