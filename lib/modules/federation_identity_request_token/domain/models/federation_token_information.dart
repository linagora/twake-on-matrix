import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'federation_token_information.g.dart';

@JsonSerializable()
class FederationTokenInformation extends Equatable {
  @JsonKey(name: "access_token")
  final String? accessToken;
  @JsonKey(name: "token_type")
  final String? tokenType;
  @JsonKey(name: "matrix_server_name")
  final String? matrixServerName;
  @JsonKey(name: "expires_in")
  final int? expiresIn;

  const FederationTokenInformation({
    this.accessToken,
    this.tokenType,
    this.matrixServerName,
    this.expiresIn,
  });

  factory FederationTokenInformation.fromJson(Map<String, dynamic> json) =>
      _$FederationTokenInformationFromJson(json);

  Map<String, dynamic> toJson() => _$FederationTokenInformationToJson(this);

  @override
  List<Object?> get props => [
    accessToken,
    tokenType,
    matrixServerName,
    expiresIn,
  ];
}
