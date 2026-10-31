import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/client_manager.dart';
import 'package:twake_chat/utils/push_helper.dart';

import '../fake_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notification = PushNotification(
    devices: [],
    eventId: r'$event',
    roomId: '!room:example.org',
    type: 'm.room.message',
  );

  group('pushHelper with an explicit client', () {
    test('a logged-out client kept for its removal stops the helper', () async {
      final loggedOut = Client('logged-out', database: MockDatabase());

      // Without the guard the helper goes on to the notification plugin,
      // which has no platform in a unit test, and rethrows.
      await pushHelper(notification, client: loggedOut);
    });
  });

  group('ClientManager.loggedIn', () {
    test('the first account to serve push skips a logged-out one', () async {
      final loggedIn = await getClient();
      final loggedOut = Client('logged-out', database: MockDatabase());

      expect(
        ClientManager.loggedIn([loggedOut, loggedIn]).firstOrNull,
        same(loggedIn),
      );
      expect(ClientManager.loggedIn([loggedOut]).firstOrNull, isNull);
    });
  });
}
