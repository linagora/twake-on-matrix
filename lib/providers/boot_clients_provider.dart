import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'boot_clients_provider.g.dart';

/// The clients created and initialised at boot (`ClientManager.getClients`),
/// in store order. Overridden when the app container is created; reading it
/// without an override is a bug.
@Riverpod(keepAlive: true)
List<Client> bootClients(Ref ref) => throw UnimplementedError(
  'bootClientsProvider must be overridden when the container is made',
);
