// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_picker_action_request.freezed.dart';
part 'drive_picker_action_request.g.dart';

@freezed
abstract class DrivePickerActionRequest with _$DrivePickerActionRequest {
  @JsonSerializable(includeIfNull: false)
  const factory DrivePickerActionRequest({
    required String label,
    num? maxFileSize,
    num? availableSize,
  }) = _DrivePickerActionRequest;

  factory DrivePickerActionRequest.fromJson(Map<String, dynamic> json) =>
      _$DrivePickerActionRequestFromJson(json);
}
