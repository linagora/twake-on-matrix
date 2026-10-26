import 'package:matrix/matrix.dart';

/// The Matrix `Client` side of the accounts: creating, listing and deleting
/// clients and the names that identify them in the store.
abstract interface class AccountClientDataSource {
  Future<Client> createClient(String clientName);

  Future<void> addClientName(String clientName);

  Future<void> removeClientName(String clientName);

  /// Disposes [client] and deletes its database.
  Future<void> disposeAndDeleteStorage(Client client);
}
