import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'federation_identity_register_response.g.dart';

@JsonSerializable()
class FederationIdentityRegisterResponse with EquatableMixin {
  FederationIdentityRegisterResponse({this.token});

  final String? token;

  factory FederationIdentityRegisterResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$FederationIdentityRegisterResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$FederationIdentityRegisterResponseToJson(this);

  @override
  List<Object?> get props => [token];
}
