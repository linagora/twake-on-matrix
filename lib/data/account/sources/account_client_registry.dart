import 'package:matrix/matrix.dart';

/// The `Client` objects of the known accounts, by client name, in the order
/// they were added. The only place that maps an account id to a `Client`.
class AccountClientRegistry {
  final Map<String, Client> _clients = {};

  Client? operator [](String id) => _clients[id];

  List<Client> get clients => List.unmodifiable(_clients.values);

  void add(Client client) => _clients[client.clientName] = client;

  Client? remove(String id) => _clients.remove(id);

  void replaceAll(Iterable<Client> clients) {
    _clients
      ..clear()
      ..addEntries(clients.map((c) => MapEntry(c.clientName, c)));
  }
}
