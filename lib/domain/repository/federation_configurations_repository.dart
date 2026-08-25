import 'package:twake_chat/data/model/federation_server/federation_configuration.dart';

abstract class FederationConfigurationsRepository {
  Future<FederationConfigurations> getFederationConfigurations(String userId);

  Future<void> saveFederationConfigurations(
    String userId,
    FederationConfigurations federationConfigurations,
  );

  Future<void> deleteFederationConfigurations(String userId);
}
