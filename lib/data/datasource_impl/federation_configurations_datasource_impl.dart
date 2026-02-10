import 'package:fluffychat/data/datasource/federation_configurations_datasource.dart';
import 'package:fluffychat/data/hive/dto/federation_configurations_hive_obj.dart';
import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/data/model/federation_server/federation_configuration.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/exception/federation_configuration_not_found.dart';
import 'package:fluffychat/utils/copy_map.dart';
import 'package:matrix/matrix.dart';

class HiveFederationConfigurationsDatasourceImpl
    implements FederationConfigurationsDatasource {
  @override
  Future<FederationConfigurations> getFederationConfigurations(
    String userId,
  ) async {
    final hiveCollectionFederationDatabase = await getIt
        .getAsync<HiveCollectionToMDatabase>();
    final cachedFederationConfigurations =
        await hiveCollectionFederationDatabase.federationConfigurationsBox.get(
          userId,
        );
    if (cachedFederationConfigurations != null) {
      final federationConfigurationsHiveObj =
          FederationConfigurationsHiveObj.fromJson(
            copyMap(cachedFederationConfigurations),
          );

      return FederationConfigurations(
        fedServerInformation: federationConfigurationsHiveObj
            .federationServerInformation
            .toFederationServerInformation(),
        identityServerInformation:
            federationConfigurationsHiveObj.identityServerUrl != null
            ? IdentityServerInformation(
                baseUrl: Uri.parse(
                  federationConfigurationsHiveObj.identityServerUrl!,
                ),
              )
            : null,
      );
    }
    throw FederationConfigurationNotFound();
  }

  @override
  Future<void> saveFederationConfigurations(
    String userId,
    FederationConfigurations federationConfiguration,
  ) async {
    final hiveCollectionFederationDatabase = await getIt
        .getAsync<HiveCollectionToMDatabase>();
    return hiveCollectionFederationDatabase.federationConfigurationsBox.put(
      userId,
      FederationConfigurationsHiveObj.fromFederationConfigurations(
        federationConfiguration,
      ).toJson(),
    );
  }

  @override
  Future<void> deleteFederationConfigurations(String userId) async {
    final hiveCollectionFederationDatabase = getIt
        .get<HiveCollectionToMDatabase>();
    return hiveCollectionFederationDatabase.federationConfigurationsBox.delete(
      userId,
    );
  }
}
