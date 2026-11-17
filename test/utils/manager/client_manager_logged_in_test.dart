import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/client_manager.dart';
import 'package:twake_chat/utils/string_extension.dart';

import '../../data/account/fakes.dart';
import '../../fake_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('ClientManager.serving', () {
    test('the preferred client is kept while it holds a session', () async {
      final preferred = await getClient();
      final other = await getClient();

      expect(ClientManager.serving(preferred, [other]), same(preferred));
    });

    test('a logged-out preferred client gives way to a held logged-in '
        'one, without a new client', () async {
      final loggedOut = Client('logged-out', database: MockDatabase());
      final held = await getClient();

      expect(ClientManager.serving(loggedOut, [loggedOut, held]), same(held));
    });

    test('nobody holds a session: the preferred client stays', () {
      final loggedOut = Client('logged-out', database: MockDatabase());

      expect(ClientManager.serving(loggedOut, [loggedOut]), same(loggedOut));
    });
  });

  group('ClientManager.receiving', () {
    final sender = FakeAccountClient('sender', userID: '@sender:s');
    final receiver = FakeAccountClient('receiver', userID: '@receiver:s');

    test('the push names its account by Matrix id', () {
      expect(
        ClientManager.receiving([sender, receiver], userId: '@receiver:s'),
        same(receiver),
      );
    });

    test('the push names its account by pusher identifier', () {
      expect(
        ClientManager.receiving([
          sender,
          receiver,
        ], pusherIdentifier: '@receiver:s'.sha256Hash),
        same(receiver),
      );
    });

    test('the push names no held account: nothing is returned', () {
      expect(
        ClientManager.receiving(
          [sender, receiver],
          userId: '@other:s',
          pusherIdentifier: '@other:s'.sha256Hash,
        ),
        isNull,
      );
      expect(ClientManager.receiving([sender, receiver]), isNull);
    });

    test('a logged-out account does not receive the push', () {
      final loggedOut = FakeAccountClient(
        'gone',
        userID: '@receiver:s',
        logged: false,
      );

      expect(
        ClientManager.receiving([loggedOut], userId: '@receiver:s'),
        isNull,
      );
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
