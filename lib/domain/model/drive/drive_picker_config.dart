import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_picker_config.freezed.dart';

@freezed
abstract class DrivePickerAction with _$DrivePickerAction {
  const factory DrivePickerAction({
    required String label,
    num? maxFileSize,
    num? availableSize,
  }) = _DrivePickerAction;
}

@freezed
abstract class DrivePickerConfig with _$DrivePickerConfig {
  const factory DrivePickerConfig({
    required DrivePickerAction linkAction,
    DrivePickerAction? attachmentAction,
    @Default(false) bool isDark,
  }) = _DrivePickerConfig;
}
