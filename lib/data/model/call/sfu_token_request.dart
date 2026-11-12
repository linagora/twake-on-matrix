import 'package:json_annotation/json_annotation.dart';

part 'sfu_token_request.g.dart';

/// The body of `POST <token service>/sfu/get` (MSC4195).
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class SfuTokenRequest {
  const SfuTokenRequest({
    required this.room,
    required this.openidToken,
    required this.deviceId,
  });

  final String room;
  final Map<String, Object?> openidToken;
  final String deviceId;

  Map<String, dynamic> toJson() => _$SfuTokenRequestToJson(this);
}
