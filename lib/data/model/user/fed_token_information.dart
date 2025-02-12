import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fed_token_information.g.dart';

@JsonSerializable()
class FedTokenInformation with EquatableMixin {
  @JsonKey(name: 'access_token')
  final String? fedAccessToken;
  @JsonKey(name: 'token_type')
  final String? fedTokenType;
  @JsonKey(name: 'matrix_server_name')
  final String? matrixServerName;
  @JsonKey(name: 'expires_in')
  final int? fedTokenExpiresIn;

  FedTokenInformation({
    this.fedAccessToken,
    this.fedTokenType,
    this.matrixServerName,
    this.fedTokenExpiresIn,
  });

  factory FedTokenInformation.fromJson(Map<String, dynamic> json) =>
      _$FedTokenInformationFromJson(json);

  Map<String, dynamic> toJson() => _$FedTokenInformationToJson(this);

  @override
  List<Object?> get props => [
        fedAccessToken,
        fedTokenType,
        matrixServerName,
        fedTokenExpiresIn,
      ];
}
