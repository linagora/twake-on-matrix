import 'package:twake_chat/data/model/federation_server/federation_configuration.dart';

abstract class FederationConfigurationsDatasource {
  Future<FederationConfigurations> getFederationConfigurations(String userId);

  Future<void> saveFederationConfigurations(
    String userId,
    FederationConfigurations federationConfiguration,
  );

  Future<void> deleteFederationConfigurations(String userId);
}
