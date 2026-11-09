// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../fake_client.dart' as fake;

/// The device storage, counting the saves of the thread counters.
class _CountingPrefsStore extends InMemorySharedPreferencesStore {
  _CountingPrefsStore() : super.empty();

  int writes = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (key.contains('thread_unread_')) writes++;
    return super.setValue(valueType, key, value);
  }
}

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

  /// THR-M-09, maintainer-side decision (09/11): the follow lookup reads the
  /// device database first, without network, then asks the server at most
  /// once, only when the root is missing there or does not say participated.
  /// The rooms are real rooms of the SDK: `Room.getEventById` asks the
  /// server itself when the database misses, so only the counts of database
  /// reads and of server requests tell the two apart.
  late _StoredRoots database;
  late List<bool> participatedOnLookup;
  late bool cachedRootHasAggregate;

  /// Whether the device database holds the root at all.
  late bool rootStored;

  /// What `GET /rooms/{roomId}/event/{rootId}` says, one answer per call
  /// (the last one repeats); an [Exception] makes the call fail.
  late List<Object> serverParticipatedOnLookup;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    participatedOnLookup = [false];
    cachedRootHasAggregate = true;
    rootStored = true;
    serverParticipatedOnLookup = [false];
    var lookups = 0;
    database = _StoredRoots((eventId, room) {
      if (eventId != rootId || !rootStored) return null;
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
    when(client.database).thenReturn(database);
    final room = Room(id: roomId, client: client);
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
      // THR-M-07: the user's own reply, from any device, comes through the
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

      expect(database.reads[rootId], 1);
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

      expect(database.reads[rootId], 1);
      verifyNever(client.getOneRoomEvent(any, any));
      expect(threadOf(store)?.followed, isTrue);
    });

    test('a root missing from the device database costs one server '
        'request, the server saying not participated', () async {
      rootStored = false;
      serverParticipatedOnLookup = [false];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      store.apply(counts(1));
      await pumpEventQueue();

      expect(database.reads[rootId], 1);
      verify(client.getOneRoomEvent(roomId, rootId)).called(1);
      expect(threadOf(store)?.followed, isFalse);
    });

    test('a root missing from the device database costs one server '
        'request, the server saying participated', () async {
      rootStored = false;
      serverParticipatedOnLookup = [true];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      store.apply(counts(1));
      await pumpEventQueue();

      expect(database.reads[rootId], 1);
      verify(client.getOneRoomEvent(roomId, rootId)).called(1);
      expect(threadOf(store)?.followed, isTrue);
    });

    test('a root missing from the device database, 50 new replies: one '
        'server request in all', () async {
      rootStored = false;
      serverParticipatedOnLookup = [false];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      for (var n = 1; n <= 50; n++) {
        store.apply(counts(n));
        await pumpEventQueue();
      }

      verify(client.getOneRoomEvent(roomId, rootId)).called(1);
      expect(threadOf(store)?.followed, isFalse);
    });

    test('a "not participated" from the server is kept: 50 new replies ask '
        'the server once', () async {
      // THR-M-07: one lookup per thread, not one per counter increase.
      serverParticipatedOnLookup = [false];
      final client = clientNamed('account-a');
      final store = ThreadUnreadStore(client: client);

      for (var n = 1; n <= 50; n++) {
        store.apply(counts(n));
        await pumpEventQueue();
      }

      verify(client.getOneRoomEvent(roomId, rootId)).called(1);
      expect(database.reads[rootId], 1);
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

  /// THR-M-09, perf (roast 5): after a long absence, one catch-up sync can
  /// raise the counters of many threads the user does not follow. Each is
  /// looked up once, and only a few run at a time.
  group('many lookups of the follow state at once', () {
    /// The database holds none of these roots: each comes from the server.
    late MockClient client;
    late Map<String, int> serverCalls;
    late List<Completer<void>> pending;
    late int inFlight;
    late int maxInFlight;

    MatrixEvent rootFromServer(String root) => MatrixEvent(
      type: EventTypes.Message,
      content: {'msgtype': 'm.text', 'body': 'root'},
      eventId: root,
      senderId: alice,
      originServerTs: DateTime.utc(2026, 11, 6),
      roomId: roomId,
      unsigned: {
        'm.relations': {
          'm.thread': {'count': 4, 'current_user_participated': false},
        },
      },
    );

    /// The server answers [root] once the test lets it ([pending]).
    void serve(String root, {bool held = false}) {
      when(client.getOneRoomEvent(roomId, root)).thenAnswer((_) async {
        serverCalls.update(root, (n) => n + 1, ifAbsent: () => 1);
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        if (held) {
          final answer = Completer<void>();
          pending.add(answer);
          await answer.future;
        }
        inFlight--;
        return rootFromServer(root);
      });
    }

    setUp(() {
      serverCalls = {};
      pending = [];
      inFlight = 0;
      maxInFlight = 0;
      client = clientNamed('account-a');
    });

    test('many threads raised at once: never more than 3 lookups in flight, '
        'and every thread is looked up once', () async {
      final roots = [for (var n = 0; n < 12; n++) '\$root_$n'];
      for (final root in roots) {
        serve(root, held: true);
      }
      final store = ThreadUnreadStore(client: client);

      store.apply({
        roomId: {
          for (final root in roots)
            root: (notificationCount: 5, highlightCount: 0),
        },
      });
      await pumpEventQueue();
      expect(inFlight, greaterThan(0), reason: 'the lookups started');
      expect(maxInFlight, lessThanOrEqualTo(3));

      // The server answers, one at a time; the next lookups follow.
      for (var turn = 0; turn < 100 && pending.isNotEmpty; turn++) {
        pending.removeAt(0).complete();
        await pumpEventQueue();
        expect(maxInFlight, lessThanOrEqualTo(3));
      }

      // Every thread looked up, each with one server request.
      expect(serverCalls, {for (final root in roots) root: 1});
      expect(store.threadsOf(roomId).where((t) => t.followed), isEmpty);
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

  /// Spec §5: every remembered reply id and every counter change
  /// rewrote the whole saved state. A catch-up sync brings hundreds of
  /// thread replies, about a millisecond apart (one database write each in
  /// the SDK): the saves are coalesced, and the last state is still saved.
  group('saves of a burst', () {
    late _CountingPrefsStore prefs;

    setUp(() {
      prefs = _CountingPrefsStore();
      SharedPreferencesStorePlatform.instance = prefs;
    });

    test('300 thread replies remembered in a row are saved at most twice, '
        'the last one included', () {
      fakeAsync((async) {
        final store = ThreadUnreadStore(client: clientNamed('account-a'));

        for (var i = 0; i < 300; i++) {
          store.rememberThreadReply(roomId, '\$reply$i');
          async.elapse(const Duration(milliseconds: 1));
        }
        async.elapse(const Duration(seconds: 10));

        expect(prefs.writes, lessThanOrEqualTo(2));
        final after = ThreadUnreadStore(client: clientNamed('account-a'));
        after.restore();
        async.flushMicrotasks();
        expect(after.knownThreadReplyIds(roomId), contains(r'$reply0'));
        expect(after.knownThreadReplyIds(roomId), contains(r'$reply299'));
      });
    });

    test('100 counter changes in a row are saved at most twice, the last '
        'one included', () {
      fakeAsync((async) {
        final store = ThreadUnreadStore(client: clientNamed('account-a'));

        for (var n = 1; n <= 100; n++) {
          store.apply(counts(n));
          async.elapse(const Duration(milliseconds: 1));
        }
        async.elapse(const Duration(seconds: 10));

        expect(prefs.writes, lessThanOrEqualTo(2));
        final after = ThreadUnreadStore(client: clientNamed('account-a'));
        after.restore();
        async.flushMicrotasks();
        expect(threadOf(after)?.notificationCount, 100);
      });
    });

    test('a logout during a burst wins over the save still to come', () {
      fakeAsync((async) {
        final store = ThreadUnreadStore(client: clientNamed('account-a'));
        for (var i = 0; i < 50; i++) {
          store.rememberThreadReply(roomId, '\$reply$i');
          store.apply(counts(i + 1));
          async.elapse(const Duration(milliseconds: 1));
        }

        store.clear();
        async.elapse(const Duration(seconds: 10));

        final next = ThreadUnreadStore(client: clientNamed('account-a'));
        next.restore();
        async.flushMicrotasks();
        expect(next.knownThreadReplyIds(roomId), isEmpty);
        expect(next.threadsOf(roomId), isEmpty);
      });
    });
  });
}

/// The device database: answers the roots it holds ([answer] returns null
/// for the others) and counts the reads per event id.
class _StoredRoots extends fake.MockDatabase {
  _StoredRoots(this.answer);

  final Event? Function(String eventId, Room room) answer;
  final Map<String, int> reads = {};

  @override
  Future<Event?> getEventById(String eventId, Room room) async {
    reads.update(eventId, (n) => n + 1, ifAbsent: () => 1);
    return answer(eventId, room);
  }
}
