import 'package:fluffychat/data/datasource/federation_configurations_datasource.dart';
import 'package:fluffychat/data/model/federation_server/federation_configuration.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/federation_configurations_repository.dart';

class FederationConfigurationsRepositoryImpl
    implements FederationConfigurationsRepository {
  final FederationConfigurationsDatasource federationConfigurationsDatasource =
      getIt.get<FederationConfigurationsDatasource>();

  @override
  Future<FederationConfigurations> getFederationConfigurations(String userId) {
    return federationConfigurationsDatasource.getFederationConfigurations(
      userId,
    );
  }

  @override
  Future<void> saveFederationConfigurations(
    String userId,
    FederationConfigurations federationConfigurations,
  ) {
    return federationConfigurationsDatasource.saveFederationConfigurations(
      userId,
      federationConfigurations,
    );
  }

  @override
  Future<void> deleteFederationConfigurations(String userId) {
    return federationConfigurationsDatasource.deleteFederationConfigurations(
      userId,
    );
  }
}
