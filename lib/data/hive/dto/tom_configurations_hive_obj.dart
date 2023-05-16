import 'package:equatable/equatable.dart';
import 'package:fluffychat/data/hive/dto/tom_server_information_hive_obj.dart';
import 'package:fluffychat/data/hive/hive_constants.dart';
import 'package:fluffychat/domain/model/tom_configurations.dart';
import 'package:hive_flutter/adapters.dart';

part 'tom_configurations_hive_obj.g.dart';

@HiveType(typeId: HiveConstants.typeIdTomConfiguration)
class ToMConfigurationsHiveObj extends HiveObject with EquatableMixin{
  @HiveField(0)
  final ToMServerInformationHiveObj tomServerInformation;

  @HiveField(1)
  final String? identityServerUrl;

  ToMConfigurationsHiveObj({
    required this.tomServerInformation,
    this.identityServerUrl,
  });

  factory ToMConfigurationsHiveObj.fromToMConfigurations(ToMConfigurations toMConfigurations) {
    return ToMConfigurationsHiveObj(
      tomServerInformation: ToMServerInformationHiveObj.fromToMServerInformation(toMConfigurations.tomServerInformation),
      identityServerUrl: toMConfigurations.identityServerInformation?.baseUrl.toString(),
    );
  }

  @override
  List<Object?> get props => [tomServerInformation, identityServerUrl];
}