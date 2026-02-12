import 'package:equatable/equatable.dart';
import 'package:fluffychat/data/hive/dto/federation_server_information_hive_obj.dart';
import 'package:fluffychat/data/model/federation_server/federation_configuration.dart';
import 'package:json_annotation/json_annotation.dart';

part 'federation_configurations_hive_obj.g.dart';

@JsonSerializable(explicitToJson: true)
class FederationConfigurationsHiveObj with EquatableMixin {
  final FederationServerInformationHiveObj federationServerInformation;

  final String? identityServerUrl;

  FederationConfigurationsHiveObj({
    required this.federationServerInformation,
    required this.identityServerUrl,
  });

  factory FederationConfigurationsHiveObj.fromFederationConfigurations(
    FederationConfigurations federationConfigurations,
  ) {
    return FederationConfigurationsHiveObj(
      federationServerInformation:
          FederationServerInformationHiveObj.fromFederationServerInformation(
            federationConfigurations.fedServerInformation,
          ),
      identityServerUrl: federationConfigurations
          .identityServerInformation
          ?.baseUrl
          .toString(),
    );
  }

  factory FederationConfigurationsHiveObj.fromJson(Map<String, dynamic> json) =>
      _$FederationConfigurationsHiveObjFromJson(json);

  Map<String, dynamic> toJson() =>
      _$FederationConfigurationsHiveObjToJson(this);

  @override
  List<Object?> get props => [federationServerInformation, identityServerUrl];
}
