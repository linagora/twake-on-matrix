import 'package:fluffychat/data/datasource/tom_configurations_datasource.dart';
import 'package:fluffychat/data/hive/dto/tom_configurations_hive_obj.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/exception/tom_configuration_not_found.dart';
import 'package:fluffychat/domain/model/tom_configurations.dart';
import 'package:matrix/matrix.dart';

class HiveToMConfigurationDatasource implements ToMConfigurationsDatasource {
  @override
  Future<ToMConfigurations> getTomConfigurations(String userId) async {
    final hiveCollectionToMDatabase =
        await getIt.getAsync<HiveCollectionToMDatabase>();
    final cachedConfiguration =
        await hiveCollectionToMDatabase.tomConfigurationsBox.get(userId);
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
        authUrl: toMConfigurationsHiveObj.authUrl,
        loginType: toMConfigurationsHiveObj.loginType,
      );
    } else {
      throw ToMConfigurationNotFound();
    }
  }

  @override
  Future<void> saveTomConfigurations(
    String userId,
    ToMConfigurations toMConfigurations,
  ) async {
    final hiveCollectionToMDatabase =
        await getIt.getAsync<HiveCollectionToMDatabase>();
    return hiveCollectionToMDatabase.tomConfigurationsBox.put(
      userId,
      ToMConfigurationsHiveObj.fromToMConfigurations(toMConfigurations)
          .toJson(),
    );
  }

  @override
  Future<void> deleteTomConfigurations(String userId) {
    final hiveCollectionToMDatabase = getIt.get<HiveCollectionToMDatabase>();
    return hiveCollectionToMDatabase.tomConfigurationsBox.delete(userId);
  }
}
