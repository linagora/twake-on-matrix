import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';
import 'package:twake_chat/utils/client_manager.dart';
import 'package:twake_chat/utils/open_sqflite_db.dart';

/// Wraps the statics of [ClientManager], which stays as it is for now.
class ClientManagerAccountDataSource implements AccountClientDataSource {
  ClientManagerAccountDataSource();

  /// Clients whose disposal worked, so a retry after a failed delete does not
  /// dispose them twice. A disposal that fails is not recorded and is retried.
  final Set<Client> _disposed = {};

  @override
  Future<List<Client>> loadClients({required bool initialize}) =>
      ClientManager.getClients(initialize: initialize);

  @override
  Future<Client> createClient(String clientName) =>
      ClientManager.createClient(clientName);

  @override
  Future<void> addClientName(String clientName) =>
      ClientManager.addClientNameToStore(clientName);

  @override
  Future<void> removeClientName(String clientName) =>
      ClientManager.removeClientNameFromStore(clientName);

  @override
  Future<void> disposeAndDeleteStorage(Client client) async {
    final database = client.database;
    if (!_disposed.contains(client)) {
      await client.dispose(closeDatabase: false);
      _disposed.add(client);
    }
    await database.delete();
    if (database is MatrixSdkDatabase && database.database?.path != null) {
      await deleteSqfliteDb(database.database!.path);
    }
    _disposed.remove(client);
  }
}
