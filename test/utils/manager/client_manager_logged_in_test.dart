import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/client_manager.dart';

import '../../fake_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClientManager.dropsLoggedOut', () {
    test('two clients that are not initialised are kept', () {
      final clients = [
        Client('a', database: MockDatabase()),
        Client('b', database: MockDatabase()),
      ];

      expect(
        ClientManager.dropsLoggedOut(clients, initialized: false),
        isFalse,
      );
    });

    test(
      'an initialised logged-out client beside another is dropped',
      () async {
        final clients = [
          await getClient(),
          Client('logged-out', database: MockDatabase()),
        ];

        expect(
          ClientManager.dropsLoggedOut(clients, initialized: true),
          isTrue,
        );
      },
    );
  });

  group('ClientManager.loggedIn', () {
    test('a logged-out client kept for its removal is left out', () async {
      final loggedIn = await getClient();
      final loggedOut = Client('logged-out', database: MockDatabase());

      expect(loggedIn.isLogged(), isTrue);
      expect(loggedOut.isLogged(), isFalse);
      expect(
        ClientManager.loggedIn([loggedOut, loggedIn]),
        orderedEquals([loggedIn]),
      );
    });

    test('only logged-out clients leave nothing', () {
      final loggedOut = Client('logged-out', database: MockDatabase());

      expect(ClientManager.loggedIn([loggedOut]), isEmpty);
    });
  });

  group('ClientManager.firstLoggedIn', () {
    test('skips a logged-out client and returns the logged-in one', () async {
      final loggedIn = await getClient();
      final loggedOut = Client('logged-out', database: MockDatabase());

      expect(
        await ClientManager.firstLoggedIn([loggedOut, loggedIn]),
        same(loggedIn),
      );
    });

    test('no client holds a session: nothing is returned', () async {
      final loggedOut = Client('logged-out', database: MockDatabase());

      expect(await ClientManager.firstLoggedIn([loggedOut]), isNull);
      expect(await ClientManager.firstLoggedIn(const []), isNull);
    });
  });
}
