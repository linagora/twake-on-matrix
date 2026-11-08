import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';

/// THR-M-06 and spec §5 « Compteurs par fil ».
///
/// The unread counters of the threads. They notify only on
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
  late bool cachedRootHasAggregate;

  /// What `GET /rooms/{roomId}/event/{rootId}` says, one answer per call
  /// (the last one repeats); an [Exception] makes the call fail.
  late List<Object> serverParticipatedOnLookup;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    room = MockRoom();
    when(room.id).thenReturn(roomId);
    participatedOnLookup = [false];
    cachedRootHasAggregate = true;
    serverParticipatedOnLookup = [false];
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
        unsigned: cachedRootHasAggregate
            ? {
                'm.relations': {
                  'm.thread': {
                    'count': 3,
                    'current_user_participated': participated,
                  },
                },
              }
            : null,
      );
    });
  });

  MockClient clientNamed(String name) {
    final client = MockClient();
    when(client.clientName).thenReturn(name);
    when(client.userID).thenReturn(me);
    when(client.getRoomById(roomId)).thenReturn(room);
    var serverLookups = 0;
    when(client.getOneRoomEvent(roomId, rootId)).thenAnswer((_) async {
      final answer =
          serverParticipatedOnLookup[serverLookups.clamp(
            0,
            serverParticipatedOnLookup.length - 1,
          )];
      serverLookups++;
      if (answer is Exception) throw answer;
      return MatrixEvent(
        type: EventTypes.Message,
        content: {'msgtype': 'm.text', 'body': 'root'},
        eventId: rootId,
        senderId: alice,
        originServerTs: DateTime.utc(2026, 11, 6),
        roomId: roomId,
        unsigned: {
          'm.relations': {
            'm.thread': {'count': 4, 'current_user_participated': answer},
          },
        },
      );
    });
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

    test('a thread the user wrote in is followed before any counter of '
        'it arrives', () {
      // THR-M-09: the notification of a reply is decided before the thread
      // counters of its sync land.
      final store = ThreadUnreadStore(client: clientNamed('account-a'));

      store.markFollowed(roomId, rootId);

      expect(store.isFollowed(roomId, rootId), isTrue);
      expect(store.isFollowed(roomId, r'$other_root'), isFalse);
    });

    test('a thread found not followed stays so on new replies, until the '
        'user writes in it', () async {
      // Roast n°4: the user's own reply, from any device, comes through the
      // sync (TwakeClient → markFollowed); the counters need not ask again.
      final store = ThreadUnreadStore(client: clientNamed('account-a'));

      store.apply(counts(1));
      await pumpEventQueue();
      expect(threadOf(store)?.followed, isFalse);

      store.apply(counts(2));
      await pumpEventQueue();
      expect(threadOf(store)?.followed, isFalse);

      store.markFollowed(roomId, rootId);

      expect(threadOf(store)?.followed, isTrue);
    });
  });

  /// THR-M-07 (P1: following = wrote the root or replied). The root read
  /// from the database keeps the thread aggregate of the day it was stored:
  /// a reply the user sent since, from another device, is not in it.
  group('follow state read from the server', () {
    test('a thread the stored root says not participated is followed when '
        'the server says the user replied', () async {
      participatedOnLookup = [false];
      serverParticipatedOnLookup = [true];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      store.apply(counts(1));
      await pumpEventQueue();

      verify(client.getOneRoomEvent(roomId, rootId)).called(1);
      expect(threadOf(store)?.followed, isTrue);
    });

    test('a stored root without the thread aggregate is checked on the '
        'server', () async {
      cachedRootHasAggregate = false;
      serverParticipatedOnLookup = [true];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      store.apply(counts(1));
      await pumpEventQueue();

      expect(threadOf(store)?.followed, isTrue);
    });

    test('a stored root that says participated needs no server '
        'call', () async {
      participatedOnLookup = [true];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      store.apply(counts(1));
      await pumpEventQueue();

      verifyNever(client.getOneRoomEvent(any, any));
      expect(threadOf(store)?.followed, isTrue);
    });

    test('a "not participated" from the server is kept: 50 new replies ask '
        'the server once', () async {
      // Roast n°4: one lookup per thread, not one per counter increase.
      serverParticipatedOnLookup = [false];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      for (var n = 1; n <= 50; n++) {
        store.apply(counts(n));
        await pumpEventQueue();
      }

      verify(
        client.getOneRoomEvent(roomId, rootId),
      ).called(lessThanOrEqualTo(1));
      verify(room.getEventById(rootId)).called(lessThanOrEqualTo(1));
      expect(threadOf(store)?.followed, isFalse);
    });

    test('a thread kept not followed is followed once the user writes in it, '
        'and asks nothing more', () async {
      serverParticipatedOnLookup = [false];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);
      store.apply(counts(1));
      await pumpEventQueue();
      verify(client.getOneRoomEvent(roomId, rootId)).called(1);

      store.markFollowed(roomId, rootId);
      store.apply(counts(2));
      await pumpEventQueue();

      verifyNever(client.getOneRoomEvent(roomId, rootId));
      expect(threadOf(store)?.followed, isTrue);
    });

    test('a server that does not answer leaves the thread not followed, and '
        'the next reply asks again', () async {
      serverParticipatedOnLookup = [Exception('offline'), true];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      store.apply(counts(1));
      await pumpEventQueue();
      expect(threadOf(store)?.followed, isFalse);

      store.apply(counts(2));
      await pumpEventQueue();

      expect(threadOf(store)?.followed, isTrue);
    });

    test('a failed lookup is tried again once per later increase, and a '
        '"not participated" then is kept', () async {
      serverParticipatedOnLookup = [
        Exception('offline'),
        Exception('offline'),
        false,
      ];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      store.apply(counts(1));
      await pumpEventQueue();
      // The same counters again: no increase, no new call.
      store.apply(counts(1));
      await pumpEventQueue();
      verify(client.getOneRoomEvent(roomId, rootId)).called(1);

      store.apply(counts(2));
      await pumpEventQueue();
      verify(client.getOneRoomEvent(roomId, rootId)).called(1);

      store.apply(counts(3));
      await pumpEventQueue();
      verify(client.getOneRoomEvent(roomId, rootId)).called(1);

      for (var n = 4; n <= 10; n++) {
        store.apply(counts(n));
        await pumpEventQueue();
      }
      verifyNever(client.getOneRoomEvent(roomId, rootId));
      expect(threadOf(store)?.followed, isFalse);
    });
  });

  /// THR-M-01: a reply deleted loses its thread relation; the store keeps
  /// the ids of the thread replies so the main timeline still hides it.
  group('ids of the thread replies', () {
    const replyId = r'$reply';

    test('a remembered reply is known for its room only', () {
      final store = ThreadUnreadStore(client: clientNamed('account-a'));

      store.rememberThreadReply(roomId, replyId);

      expect(store.knownThreadReplyIds(roomId), contains(replyId));
      expect(store.knownThreadReplyIds('!other:example.com'), isEmpty);
    });

    test('are found again after a restart by the same account', () async {
      final before = ThreadUnreadStore(client: clientNamed('account-a'));
      before.rememberThreadReply(roomId, replyId);
      await pumpEventQueue();

      final after = ThreadUnreadStore(client: clientNamed('account-a'));
      await after.restore();

      expect(after.knownThreadReplyIds(roomId), contains(replyId));
    });

    test('another account does not see them', () async {
      final accountA = ThreadUnreadStore(client: clientNamed('account-a'));
      accountA.rememberThreadReply(roomId, replyId);
      await pumpEventQueue();

      final accountB = ThreadUnreadStore(client: clientNamed('account-b'));
      await accountB.restore();

      expect(accountB.knownThreadReplyIds(roomId), isEmpty);
    });

    test('are forgotten at logout', () async {
      final store = ThreadUnreadStore(client: clientNamed('account-a'));
      store.rememberThreadReply(roomId, replyId);
      await pumpEventQueue();

      await store.clear();
      final next = ThreadUnreadStore(client: clientNamed('account-a'));
      await next.restore();

      expect(store.knownThreadReplyIds(roomId), isEmpty);
      expect(next.knownThreadReplyIds(roomId), isEmpty);
    });

    test('are bounded: the oldest go first, the newest stay', () async {
      // ponytail: 5000 probes the bound, the cap itself is not decided.
      const remembered = 5000;
      final store = ThreadUnreadStore(client: clientNamed('account-a'));

      for (var i = 0; i < remembered; i++) {
        store.rememberThreadReply(roomId, '\$reply$i');
      }
      await pumpEventQueue();

      final known = store.knownThreadReplyIds(roomId);
      expect(known.length, lessThan(remembered));
      expect(known, contains('\$reply${remembered - 1}'));
      expect(known, isNot(contains(r'$reply0')));
    });
  });

  /// Logout: the next account on this device may carry the same clientName.
  group('after a logout', () {
    test('the next account on the device sees no thread of the previous '
        'user', () async {
      final previous = ThreadUnreadStore(client: clientNamed('account-a'));
      previous.apply(counts(3, highlights: 1));
      previous.markFollowed(roomId, rootId);
      await pumpEventQueue();

      await previous.clear();

      expect(previous.threadsOf(roomId), isEmpty);
      expect(previous.badgeOf(roomId), 0);
      final next = ThreadUnreadStore(client: clientNamed('account-a'));
      await next.restore();
      expect(next.threadsOf(roomId), isEmpty);
    });

    test('a thread followed by the previous user is not followed by the '
        'next one', () async {
      final previous = ThreadUnreadStore(client: clientNamed('account-a'));
      previous.markFollowed(roomId, rootId);
      await pumpEventQueue();
      await previous.clear();

      final next = ThreadUnreadStore(client: clientNamed('account-a'));
      await next.restore();
      next.apply(counts(1));
      await pumpEventQueue();

      expect(threadOf(next)?.followed, isFalse);
      expect(next.badgeOf(roomId), 0);
    });

    test('a save still running when the user logs out does not bring the '
        'threads back', () async {
      final previous = ThreadUnreadStore(client: clientNamed('account-a'));
      previous.apply(counts(3));
      previous.markFollowed(roomId, rootId);
      // No pause: both saves are still in flight.
      await previous.clear();
      await pumpEventQueue();

      final next = ThreadUnreadStore(client: clientNamed('account-a'));
      await next.restore();

      expect(next.threadsOf(roomId), isEmpty);
    });
  });

  group('a room the user left', () {
    const otherRoomId = '!other:example.com';

    ThreadUnreadStore storeWithTwoRooms() {
      final store = ThreadUnreadStore(client: clientNamed('account-a'));
      store.apply({
        roomId: {rootId: (notificationCount: 3, highlightCount: 1)},
        otherRoomId: {
          r'$other_root': (notificationCount: 2, highlightCount: 2),
        },
      });
      store.markFollowed(roomId, rootId);
      return store;
    }

    test('has no thread counter nor badge any more', () async {
      final store = storeWithTwoRooms();
      await pumpEventQueue();

      store.apply(const {}, leftRoomIds: const [roomId]);
      await pumpEventQueue();

      expect(store.threadsOf(roomId), isEmpty);
      expect(store.badgeOf(roomId), 0);
      expect(store.threadsOf(otherRoomId), hasLength(1));
      expect(store.badgeOf(otherRoomId), 2);
    });

    test('does not come back after a restart', () async {
      final store = storeWithTwoRooms();
      await pumpEventQueue();
      store.apply(const {}, leftRoomIds: const [roomId]);
      await pumpEventQueue();

      final restarted = ThreadUnreadStore(client: clientNamed('account-a'));
      await restarted.restore();

      expect(restarted.threadsOf(roomId), isEmpty);
      expect(restarted.threadsOf(otherRoomId), hasLength(1));
    });

    test('rejoined later, its threads are no longer followed', () async {
      final store = storeWithTwoRooms();
      await pumpEventQueue();
      store.apply(const {}, leftRoomIds: const [roomId]);
      await pumpEventQueue();

      store.apply(counts(1));
      await pumpEventQueue();

      expect(threadOf(store)?.followed, isFalse);
    });
  });

  /// THR-M-06: badge = followed threads count all their unread messages,
  /// the others only their mentions.
  group('badge of the threads of a room', () {
    const quietRootId = r'$quiet_root';

    ThreadUnreadStore storeWithTwoThreads() {
      final store = ThreadUnreadStore(client: clientNamed('account-a'));
      store.apply({
        roomId: {
          rootId: (notificationCount: 3, highlightCount: 1),
          quietRootId: (notificationCount: 5, highlightCount: 2),
        },
      });
      store.markFollowed(roomId, rootId);
      return store;
    }

    test('counts every unread message of a followed thread and only the '
        'mentions of another one', () async {
      final store = storeWithTwoThreads();
      await pumpEventQueue();

      expect(store.badgeOf(roomId), 3 + 2);
    });

    test('follows the user when they start following a thread', () async {
      final store = storeWithTwoThreads();
      await pumpEventQueue();

      store.markFollowed(roomId, quietRootId);

      expect(store.badgeOf(roomId), 3 + 5);
    });

    test('follows the new counters of a sync', () async {
      final store = storeWithTwoThreads();
      await pumpEventQueue();

      store.apply({
        roomId: {
          rootId: (notificationCount: 1, highlightCount: 0),
          quietRootId: (notificationCount: 6, highlightCount: 4),
        },
      });

      expect(store.badgeOf(roomId), 1 + 4);
    });

    test('is zero for a room without thread counters', () {
      final store = ThreadUnreadStore(client: clientNamed('account-a'));

      expect(store.badgeOf('!unknown:example.com'), 0);
    });
  });
}
