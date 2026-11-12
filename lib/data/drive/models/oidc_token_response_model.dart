import 'package:json_annotation/json_annotation.dart';

part 'oidc_token_response_model.g.dart';

/// The token endpoint answer. The id token and the refresh token are read: the
/// SSO access token is never sent to Drive.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class OidcTokenResponseModel {
  const OidcTokenResponseModel({required this.idToken, this.refreshToken});

  factory OidcTokenResponseModel.fromJson(Map<String, dynamic> json) =>
      _$OidcTokenResponseModelFromJson(json);

  final String idToken;
  final String? refreshToken;
}
