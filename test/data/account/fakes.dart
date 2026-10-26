import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';

class FakeAccountClient extends Fake implements Client {
  FakeAccountClient(this.clientName, {this.userID, this.logged = true});

  @override
  final String clientName;

  @override
  final String? userID;

  final bool logged;

  @override
  bool isLogged() => logged;
}

class FakeAccountClientDataSource implements AccountClientDataSource {
  final calls = <String>[];
  bool failDelete = false;
  bool failAddName = false;
  bool failRemoveName = false;
  bool createLoggedIn = false;

  /// Makes the clients `createClient` returns, when a test needs its own.
  Client Function(String clientName)? clientFactory;

  @override
  Future<Client> createClient(String clientName) async {
    calls.add('create:$clientName');
    final factory = clientFactory;
    if (factory != null) return factory(clientName);
    return FakeAccountClient(
      clientName,
      userID: createLoggedIn ? '@$clientName:s' : null,
      logged: createLoggedIn,
    );
  }

  @override
  Future<void> addClientName(String clientName) async {
    calls.add('add:$clientName');
    if (failAddName) throw StateError('store');
  }

  @override
  Future<void> removeClientName(String clientName) async {
    calls.add('remove:$clientName');
    if (failRemoveName) throw StateError('store');
  }

  @override
  Future<void> disposeAndDeleteStorage(Client client) async {
    calls.add('delete:${client.clientName}');
    if (failDelete) throw StateError('disk');
  }
}
