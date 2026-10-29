import 'package:matrix/matrix.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/federation_configurations_repository.dart';
import 'package:twake_chat/domain/repository/tom_configurations_repository.dart';

/// Logs [client] out and removes what the app stores for its account.
///
/// Shared by the settings logout and the forced session renewal. Clearing the
/// client also logs the notification device out and removes the recovery key
/// (`TwakeClient.clear`).
Future<void> logoutAndCleanUp(
  Client client, {
  required bool twakeSupported,
}) async {
  final userId = client.userID;
  await Future.wait([
    client.logout(),
    if (userId != null && twakeSupported)
      getIt
          .get<ToMConfigurationsRepository>()
          .deleteTomConfigurations(userId)
          .catchError(
            (e) => Logs().e('logoutAndCleanUp: ToM configurations', e),
          ),
    if (userId != null)
      getIt
          .get<FederationConfigurationsRepository>()
          .deleteFederationConfigurations(userId)
          .catchError(
            (e) => Logs().e('logoutAndCleanUp: federation configurations', e),
          ),
  ]);
}
