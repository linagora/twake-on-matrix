import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';
import 'package:twake_chat/utils/client_manager.dart';

/// How far disposing a client and deleting its storage got.
enum _Stage {
  /// The client is disposed; its storage is still there.
  disposed,

  /// The storage is deleted too: nothing is left to do.
  storageDeleted,
}

/// Adapts the statics of [ClientManager], which stays as it is for now, and
/// remembers per [Client] how far its disposal went, so a repeated call
/// resumes where the last one stopped.
class ClientManagerAccountDataSource implements AccountClientDataSource {
  ClientManagerAccountDataSource();

  /// Keyed by identity and weak: an entry goes away with its client, so
  /// nothing has to be cleared.
  final Expando<_Stage> _stages = Expando<_Stage>('disposal stage');

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
    if (_stages[client] == _Stage.storageDeleted) return;
    final database = client.database;
    if (_stages[client] == null) {
      await client.dispose(closeDatabase: false);
      _stages[client] = _Stage.disposed;
    }
    await ClientManager.deleteClientStorage(database);
    _stages[client] = _Stage.storageDeleted;
  }
}
