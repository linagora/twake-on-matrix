// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/data/model/drive/drive_enums.dart';

part 'drive_token_exchange_request.freezed.dart';
part 'drive_token_exchange_request.g.dart';

@freezed
abstract class DriveTokenExchangeRequest with _$DriveTokenExchangeRequest {
  const DriveTokenExchangeRequest._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DriveTokenExchangeRequest({
    required String idToken,
    required DriveExchangeType exchangeType,
  }) = _DriveTokenExchangeRequest;

  factory DriveTokenExchangeRequest.app({required String idToken}) =>
      DriveTokenExchangeRequest(
        idToken: idToken,
        exchangeType: DriveExchangeType.app,
      );

  factory DriveTokenExchangeRequest.fromJson(Map<String, dynamic> json) =>
      _$DriveTokenExchangeRequestFromJson(json);

  @override
  String toString() => 'DriveTokenExchangeRequest(idToken: <redacted>)';
}
