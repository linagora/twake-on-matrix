import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/model/federation_server/federation_configuration.dart';
import 'package:twake_chat/domain/model/tom_configurations.dart';
import 'package:twake_chat/domain/repository/federation_configurations_repository.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';

/// Saves the ToM and federation configuration of a user that just logged in.
/// Unlike the saves of an account switch, a failure here is an error: the
/// login is not complete without them, so the caller rolls it back.
class LoginConfigurationPersister {
  const LoginConfigurationPersister({
    required ToMConfigurationsRepository tom,
    required FederationConfigurationsRepository federation,
  }) : _tom = tom,
       _federation = federation;

  final ToMConfigurationsRepository _tom;
  final FederationConfigurationsRepository _federation;

  Future<void> saveToM(Client client, ToMConfigurations configurations) async =>
      _tom.saveTomConfigurations(_userId(client), configurations);

  /// The save of an account switch or of a restore from the well-known: the
  /// account already works without it, so a failure is logged, not thrown.
  Future<void> saveToMOrLog(
    Client client,
    ToMConfigurations configurations,
  ) async {
    try {
      await saveToM(client, configurations);
    } catch (e, s) {
      Logs().w('LoginConfigurationPersister::saveToMOrLog failed', e, s);
    }
  }

  Future<void> saveFederation(
    Client client,
    FederationConfigurations configurations,
  ) async =>
      _federation.saveFederationConfigurations(_userId(client), configurations);

  String _userId(Client client) =>
      client.userID ??
      (throw StateError('${client.clientName} has no user id to save for'));
}
