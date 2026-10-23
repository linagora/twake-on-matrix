import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_picker_session_response.freezed.dart';
part 'drive_picker_session_response.g.dart';

@freezed
abstract class DrivePickerServiceResponse with _$DrivePickerServiceResponse {
  const factory DrivePickerServiceResponse({required String href}) =
      _DrivePickerServiceResponse;

  factory DrivePickerServiceResponse.fromJson(Map<String, dynamic> json) =>
      _$DrivePickerServiceResponseFromJson(json);
}

@freezed
abstract class DrivePickerSessionAttributesResponse
    with _$DrivePickerSessionAttributesResponse {
  const factory DrivePickerSessionAttributesResponse({
    required List<DrivePickerServiceResponse> services,
    String? client,
  }) = _DrivePickerSessionAttributesResponse;

  factory DrivePickerSessionAttributesResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$DrivePickerSessionAttributesResponseFromJson(json);
}

@freezed
abstract class DrivePickerSessionDataResponse
    with _$DrivePickerSessionDataResponse {
  const factory DrivePickerSessionDataResponse({
    required String id,
    required DrivePickerSessionAttributesResponse attributes,
  }) = _DrivePickerSessionDataResponse;

  factory DrivePickerSessionDataResponse.fromJson(Map<String, dynamic> json) =>
      _$DrivePickerSessionDataResponseFromJson(json);
}

@freezed
abstract class DrivePickerSessionResponse with _$DrivePickerSessionResponse {
  const DrivePickerSessionResponse._();

  const factory DrivePickerSessionResponse({
    required DrivePickerSessionDataResponse data,
  }) = _DrivePickerSessionResponse;

  factory DrivePickerSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$DrivePickerSessionResponseFromJson(json);

  String get id => data.id;

  String? get client => data.attributes.client;

  /// Page of the first service, null when Drive returned none.
  String? get href => data.attributes.services.firstOrNull?.href;
}
