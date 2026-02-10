import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'federation_server_information.g.dart';

@JsonSerializable()
class FederationServerInformation with EquatableMixin {
  static const String fedServerKey = 'm.federated_identity_services';

  @JsonKey(name: 'base_urls')
  final List<Uri>? baseUrls;

  FederationServerInformation({this.baseUrls});

  bool get hasBaseUrls => baseUrls != null && baseUrls!.isNotEmpty;

  factory FederationServerInformation.fromJson(Map<String, dynamic> json) =>
      _$FederationServerInformationFromJson(json);

  Map<String, dynamic> toJson() => _$FederationServerInformationToJson(this);

  @override
  List<Object?> get props => [baseUrls];
}
