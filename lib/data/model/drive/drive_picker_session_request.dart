// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/data/model/drive/drive_enums.dart';
import 'package:twake_chat/data/model/drive/drive_picker_action_request.dart';

part 'drive_picker_session_request.freezed.dart';
part 'drive_picker_session_request.g.dart';

@freezed
abstract class DrivePickerThemeRequest with _$DrivePickerThemeRequest {
  const factory DrivePickerThemeRequest({required DriveThemeType type}) =
      _DrivePickerThemeRequest;

  factory DrivePickerThemeRequest.fromJson(Map<String, dynamic> json) =>
      _$DrivePickerThemeRequestFromJson(json);
}

/// `downloadLink` is sent as an explicit `null` when absent: Drive hides an
/// action set to `null` and shows its default button when it is omitted.
@freezed
abstract class DrivePickerOptionsRequest with _$DrivePickerOptionsRequest {
  @JsonSerializable(explicitToJson: true)
  const factory DrivePickerOptionsRequest({
    required DrivePickerActionRequest sharingLink,
    required DrivePickerActionRequest? downloadLink,
    required DrivePickerThemeRequest theme,
  }) = _DrivePickerOptionsRequest;

  factory DrivePickerOptionsRequest.fromJson(Map<String, dynamic> json) =>
      _$DrivePickerOptionsRequestFromJson(json);
}

@freezed
abstract class DrivePickerAttributesRequest
    with _$DrivePickerAttributesRequest {
  @JsonSerializable(explicitToJson: true)
  const factory DrivePickerAttributesRequest({
    required DriveIntentAction action,
    required DriveDocType type,
    required List<DriveIntentPermission> permissions,
    required DrivePickerOptionsRequest data,
  }) = _DrivePickerAttributesRequest;

  factory DrivePickerAttributesRequest.fromJson(Map<String, dynamic> json) =>
      _$DrivePickerAttributesRequestFromJson(json);
}

@freezed
abstract class DrivePickerSessionDataRequest
    with _$DrivePickerSessionDataRequest {
  @JsonSerializable(explicitToJson: true)
  const factory DrivePickerSessionDataRequest({
    required DriveDataType type,
    required DrivePickerAttributesRequest attributes,
  }) = _DrivePickerSessionDataRequest;

  factory DrivePickerSessionDataRequest.fromJson(Map<String, dynamic> json) =>
      _$DrivePickerSessionDataRequestFromJson(json);
}

@freezed
abstract class DrivePickerSessionRequest with _$DrivePickerSessionRequest {
  @JsonSerializable(explicitToJson: true)
  const factory DrivePickerSessionRequest({
    required DrivePickerSessionDataRequest data,
  }) = _DrivePickerSessionRequest;

  factory DrivePickerSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$DrivePickerSessionRequestFromJson(json);

  factory DrivePickerSessionRequest.pick({
    required DrivePickerActionRequest sharingLink,
    DrivePickerActionRequest? downloadLink,
    bool isDark = false,
  }) => DrivePickerSessionRequest(
    data: DrivePickerSessionDataRequest(
      type: DriveDataType.intents,
      attributes: DrivePickerAttributesRequest(
        action: DriveIntentAction.pick,
        type: DriveDocType.files,
        permissions: [DriveIntentPermission.get],
        data: DrivePickerOptionsRequest(
          sharingLink: sharingLink,
          downloadLink: downloadLink,
          theme: DrivePickerThemeRequest(
            type: isDark ? DriveThemeType.dark : DriveThemeType.light,
          ),
        ),
      ),
    ),
  );
}
