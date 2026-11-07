import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';

/// Roast #4, #5, #9: the unread counters of the threads. They notify only on
/// a real change, survive a restart (spec §5, web reload too) per account,
/// and the follow state has one source.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const roomId = '!room:example.com';
  const rootId = r'$root';
  const me = '@me:example.com';
  const alice = '@alice:example.com';

  late MockRoom room;
  late List<bool> participatedOnLookup;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

  group('the counters survive a restart', () {
    test(
      'counters and follow state are found again by the same account',
      () async {
        final before = ThreadUnreadStore(client: clientNamed('account-a'));
        before.apply(counts(3, highlights: 1));
        before.markFollowed(roomId, rootId);
        await pumpEventQueue();

        final after = ThreadUnreadStore(client: clientNamed('account-a'));
        await after.restore();

        final thread = threadOf(after);
        expect(thread, isNotNull);
        expect(thread!.notificationCount, 3);
        expect(thread.highlightCount, 1);
        expect(thread.followed, isTrue);
      },
    );

    test('another account sees none of them', () async {
      final accountA = ThreadUnreadStore(client: clientNamed('account-a'));
      accountA.apply(counts(3, highlights: 1));
      accountA.markFollowed(roomId, rootId);
      await pumpEventQueue();

      final accountB = ThreadUnreadStore(client: clientNamed('account-b'));
      await accountB.restore();

      expect(accountB.threadsOf(roomId), isEmpty);
    });
  });

  group('one source for the follow state', () {
    test('a thread the user wrote in stays followed after a restart, even '
        'when the root still says not participated', () async {
      final before = ThreadUnreadStore(client: clientNamed('account-a'));
      before.markFollowed(roomId, rootId);
      before.apply(counts(1));
      await pumpEventQueue();

      // The cached root is older than the user's reply.
      participatedOnLookup = [false];
      final after = ThreadUnreadStore(client: clientNamed('account-a'));
      await after.restore();
      after.apply(counts(2));
      await pumpEventQueue();

      expect(threadOf(after)?.followed, isTrue);
    });

    test('a thread found not followed is checked again when new replies '
        'arrive', () async {
      // The user replied from another device between the two syncs.
      participatedOnLookup = [false, true];
      final store = ThreadUnreadStore(client: clientNamed('account-a'));

      store.apply(counts(1));
      await pumpEventQueue();
      expect(threadOf(store)?.followed, isFalse);

      store.apply(counts(2));
      await pumpEventQueue();

      expect(threadOf(store)?.followed, isTrue);
    });
  });
}
