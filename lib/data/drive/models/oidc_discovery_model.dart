import 'package:json_annotation/json_annotation.dart';

part 'oidc_discovery_model.g.dart';

/// The parts of `/.well-known/openid-configuration` the sign-in reads.
@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
)
class OidcDiscoveryModel {
  const OidcDiscoveryModel({
    required this.issuer,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
  });

  factory OidcDiscoveryModel.fromJson(Map<String, dynamic> json) =>
      _$OidcDiscoveryModelFromJson(json);

  final String issuer;
  final String authorizationEndpoint;
  final String tokenEndpoint;
}
