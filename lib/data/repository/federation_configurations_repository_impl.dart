import 'package:twake_chat/data/datasource/federation_configurations_datasource.dart';
import 'package:twake_chat/data/model/federation_server/federation_configuration.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/federation_configurations_repository.dart';

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
