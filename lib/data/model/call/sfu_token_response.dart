import 'package:freezed_annotation/freezed_annotation.dart';

part 'sfu_token_response.freezed.dart';
part 'sfu_token_response.g.dart';

@Freezed(toJson: false)
abstract class SfuTokenResponse with _$SfuTokenResponse {
  const factory SfuTokenResponse({
    @JsonKey(fromJson: _stringOrNull) String? url,
    @JsonKey(fromJson: _stringOrNull) String? jwt,
  }) = _SfuTokenResponse;

  factory SfuTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$SfuTokenResponseFromJson(json);
}

String? _stringOrNull(Object? value) => value is String ? value : null;
