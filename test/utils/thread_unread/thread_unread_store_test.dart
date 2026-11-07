import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';

/// Roast #4: the unread counters of the threads notify only on a real
/// change, and a thread's activity moves only when it gets new messages.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const roomId = '!room:example.com';
  const rootId = r'$root';
  const me = '@me:example.com';
  const alice = '@alice:example.com';

  late MockRoom room;
  late List<bool> participatedOnLookup;

  setUp(() {
    room = MockRoom();
    when(room.id).thenReturn(roomId);
    participatedOnLookup = [false];
    var lookups = 0;
    when(room.getEventById(rootId)).thenAnswer((_) async {
      final participated =
          participatedOnLookup[lookups.clamp(
            0,
            participatedOnLookup.length - 1,
          )];
      lookups++;
      return Event(
        type: EventTypes.Message,
        content: {'msgtype': 'm.text', 'body': 'root'},
        eventId: rootId,
        senderId: alice,
        originServerTs: DateTime.utc(2026, 11, 6),
        room: room,
        unsigned: {
          'm.relations': {
            'm.thread': {'count': 3, 'current_user_participated': participated},
          },
        },
      );
    });
  });

  MockClient clientNamed(String name) {
    final client = MockClient();
    when(client.clientName).thenReturn(name);
    when(client.userID).thenReturn(me);
    when(client.getRoomById(roomId)).thenReturn(room);
    return client;
  }

  Map<String, Map<String, ThreadCounts>> counts(
    int notifications, {
    int highlights = 0,
  }) => {
    roomId: {
      rootId: (notificationCount: notifications, highlightCount: highlights),
    },
  };

  ThreadUnread? threadOf(ThreadUnreadStore store) =>
      store.threadsOf(roomId).where((t) => t.rootEventId == rootId).firstOrNull;

  group('listeners are told only about real changes', () {
    test('the same counters received twice notify once', () async {
      final store = ThreadUnreadStore(client: clientNamed('account-a'));
      var notifications = 0;
      store.addListener(() => notifications++);

      store.apply(counts(2));
      await pumpEventQueue();
      store.apply(counts(2));
      await pumpEventQueue();

      expect(notifications, 1);
    });

    test('a sync carrying a room without thread counters, when it had '
        'none, notifies nobody', () async {
      final store = ThreadUnreadStore(client: clientNamed('account-a'));
      var notifications = 0;
      store.addListener(() => notifications++);

      // What parseSyncUnreadThreadNotifications returns for a room whose
      // update carries `unread_notifications` only.
      store.apply({roomId: {}});
      await pumpEventQueue();

      expect(notifications, 0);
    });

    test('a counter that changes notifies', () async {
      final store = ThreadUnreadStore(client: clientNamed('account-a'));
      store.apply(counts(2));
      await pumpEventQueue();
      var notifications = 0;
      store.addListener(() => notifications++);

      store.apply(counts(3));
      await pumpEventQueue();

      expect(notifications, 1);
    });
  });

  group('activity of a thread', () {
    test('a thread read on another device keeps its last activity', () async {
      final store = ThreadUnreadStore(client: clientNamed('account-a'));
      store.apply(counts(3));
      await pumpEventQueue();
      final activity = threadOf(store)?.lastActivity;
      expect(activity, isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      store.apply(counts(1));
      await pumpEventQueue();

      expect(threadOf(store)?.lastActivity, activity);
    });
  });
}
