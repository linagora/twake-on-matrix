import 'package:fluffychat/data/datasource/tom_configurations_datasource.dart';
import 'package:fluffychat/data/hive/dto/tom_configurations_hive_obj.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/exception/tom_configuration_not_found.dart';
import 'package:fluffychat/domain/model/tom_configurations.dart';
import 'package:matrix/matrix.dart';

class HiveToMConfigurationDatasource implements ToMConfigurationsDatasource {
  @override
  Future<ToMConfigurations> getTomConfigurations(String clientName) async {
    final hiveCollectionToMDatabase =
        await getIt.getAsync<HiveCollectionToMDatabase>();
    final cachedConfiguration =
        await hiveCollectionToMDatabase.tomConfigurationsBox.get(clientName);
    if (cachedConfiguration != null) {
      final toMConfigurationsHiveObj =
          ToMConfigurationsHiveObj.fromJson(copyMap(cachedConfiguration));
      return ToMConfigurations(
        tomServerInformation: toMConfigurationsHiveObj.tomServerInformation
            .toToMServerInformation(),
        identityServerInformation: toMConfigurationsHiveObj.identityServerUrl !=
                null
            ? IdentityServerInformation(
                baseUrl: Uri.parse(toMConfigurationsHiveObj.identityServerUrl!),
              )
            : null,
      );
    } else {
      throw ToMConfigurationNotFound();
    }
  }

  @override
  Future<void> saveTomConfigurations(
    String clientName,
    ToMConfigurations toMConfigurations,
  ) async {
    final hiveCollectionToMDatabase =
        await getIt.getAsync<HiveCollectionToMDatabase>();
    return hiveCollectionToMDatabase.tomConfigurationsBox.put(
      clientName,
      ToMConfigurationsHiveObj.fromToMConfigurations(toMConfigurations)
          .toJson(),
    );
  }
}
