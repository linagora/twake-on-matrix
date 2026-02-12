import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'federation_register_response.g.dart';

@JsonSerializable()
class FederationRegisterResponse extends Equatable {
  @JsonKey(name: "token")
  final String? token;

  const FederationRegisterResponse({this.token});

  factory FederationRegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$FederationRegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FederationRegisterResponseToJson(this);

  @override
  List<Object?> get props => [token];
}
