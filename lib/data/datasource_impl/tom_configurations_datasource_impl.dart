import 'package:fluffychat/data/datasource/tom_configurations_datasource.dart';
import 'package:fluffychat/data/hive/dto/tom_configurations_hive_obj.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/exception/tom_configuration_not_found.dart';
import 'package:fluffychat/domain/model/tom_configurations.dart';
import 'package:matrix/matrix.dart';

class HiveToMConfigurationDatasource implements ToMConfigurationsDatasource {
  late HiveCollectionToMDatabase _hiveCollectionToMDatabase;

  @override
  Future<ToMConfigurations> getTomConfigurations(String clientName) async {
    _hiveCollectionToMDatabase =
        await getIt.getAsync<HiveCollectionToMDatabase>();
    final cachedConfiguration =
        await _hiveCollectionToMDatabase.tomConfigurationsBox.get(clientName);
    if (cachedConfiguration != null) {
      return ToMConfigurations(
        tomServerInformation:
            cachedConfiguration.tomServerInformation.toToMServerInformation(),
        identityServerInformation: cachedConfiguration.identityServerUrl != null
            ? IdentityServerInformation(
                baseUrl: Uri.parse(cachedConfiguration.identityServerUrl!))
            : null,
      );
    } else {
      throw ToMConfigurationNotFound();
    }
  }

  @override
  Future<void> saveTomConfigurations(
      String clientName, ToMConfigurations toMConfigurations) async {
    _hiveCollectionToMDatabase =
        await getIt.getAsync<HiveCollectionToMDatabase>();
    return _hiveCollectionToMDatabase.tomConfigurationsBox.put(
      clientName,
      ToMConfigurationsHiveObj.fromToMConfigurations(toMConfigurations),
    );
  }
}
