import 'package:matrix/matrix.dart';

/// The `Client` objects of the known accounts, by client name. The only place
/// that maps an account id to a `Client`.
class AccountClientRegistry {
  final Map<String, Client> _clients = {};

  Client? operator [](String id) => _clients[id];

  void add(Client client) => _clients[client.clientName] = client;

  Client? remove(String id) => _clients.remove(id);

  void replaceAll(Iterable<Client> clients) {
    _clients
      ..clear()
      ..addEntries(clients.map((c) => MapEntry(c.clientName, c)));
  }
}
