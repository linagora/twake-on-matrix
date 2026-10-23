// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_token_exchange_response.freezed.dart';
part 'drive_token_exchange_response.g.dart';

@freezed
abstract class DriveTokenExchangeResponse with _$DriveTokenExchangeResponse {
  const DriveTokenExchangeResponse._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DriveTokenExchangeResponse({required String accessToken}) =
      _DriveTokenExchangeResponse;

  factory DriveTokenExchangeResponse.fromJson(Map<String, dynamic> json) =>
      _$DriveTokenExchangeResponseFromJson(json);

  @override
  String toString() => 'DriveTokenExchangeResponse(accessToken: <redacted>)';
}
