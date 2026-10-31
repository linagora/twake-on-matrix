import 'package:matrix/matrix.dart';

/// The `Client` objects of the known accounts, by client name. The only place
/// that maps an account id to a `Client`.
class AccountClientRegistry {
  final Map<String, Client> _clients = {};

  Client? operator [](String id) => _clients[id];

  void add(Client client) => _clients[client.clientName] = client;

  Client? remove(String id) => _clients.remove(id);

  /// The clients, in the order they were added.
  Iterable<Client> get clients => _clients.values;

  bool _adopted = false;

  /// Takes the boot [clients] over, once per registry: a repository built
  /// again on the same registry must not drop the accounts added since boot.
  /// Returns false, and changes nothing, when they were already taken over.
  bool adoptOnce(Iterable<Client> clients) {
    if (_adopted) return false;
    _adopted = true;
    _clients
      ..clear()
      ..addEntries(clients.map((c) => MapEntry(c.clientName, c)));
    return true;
  }
}
