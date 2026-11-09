import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../fake_client.dart';

/// Stored events of a room, newest first, paged like the SDK database.
class _StoredEventsDatabase extends MockDatabase {
  _StoredEventsDatabase(this.events);

  final List<Event> events;

  @override
  Future<List<Event>> getEventList(
    Room room, {
    int start = 0,
    bool onlySending = false,
    int? limit,
  }) async {
    final stored = events
        .where((e) => !onlySending || e.status.isSending)
        .skip(start);
    return (limit == null ? stored : stored.take(limit)).toList();
  }
}

/// THR-M-06 « Marquer comme lu ».
///
/// "Mark as read" on a room sends its main receipt on the
/// newest main timeline event, found among the stored events of the room,
/// even when the most recent ones are all thread replies.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const roomId = '!room:example.com';
  const rootId = r'$root';
  const me = '@me:example.com';
  const bob = '@bob:example.com';

  late _ThreadClient client;
  late Room room;

  DateTime at(int minute) =>
      DateTime.utc(2026, 11, 6, 10).add(Duration(minutes: minute));

  Event threadReply(int i, int minute) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': 'reply $i',
      'm.relates_to': {
        'rel_type': RelationshipTypes.thread,
        'event_id': rootId,
        'is_falling_back': true,
      },
    },
    eventId: '\$thread_reply_$i',
    senderId: bob,
    originServerTs: at(minute),
    room: room,
  );

  Event mainMessage(String eventId, int minute) => Event(
    type: EventTypes.Message,
    content: {'msgtype': 'm.text', 'body': 'main $eventId'},
    eventId: eventId,
    senderId: bob,
    originServerTs: at(minute),
    room: room,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = _ThreadClient();
    when(client.clientName).thenReturn('account-a');
    when(client.userID).thenReturn(me);
    when(client.receiptsPublicByDefault).thenReturn(true);
    when(
      client.roomPreviewLastEvents,
    ).thenReturn({EventTypes.Message, EventTypes.Encrypted});
    room = Room(id: roomId, client: client);
  });

  test('the main receipt lands on the main message hidden behind 40 thread '
      'replies', () async {
    // Newest first: 40 replies in a busy thread, then the last message of
    // the main timeline, then older history.
    final stored = [
      for (var i = 0; i < 40; i++) threadReply(i, 100 - i),
      mainMessage(r'$main', 50),
      mainMessage(r'$older_main', 40),
      mainMessage(rootId, 30),
    ];
    when(client.database).thenReturn(_StoredEventsDatabase(stored));
    room.lastEvent = stored.first;

    await room.markRoomAndAllThreadsRead();

    verify(
      client.postReceipt(roomId, ReceiptType.mRead, r'$main', threadId: 'main'),
    ).called(1);
    verifyNever(
      client.postReceipt(
        any,
        any,
        argThat(startsWith(r'$thread_reply_')),
        threadId: 'main',
      ),
    );
  });

  test('a main message behind a few thread replies gets the main '
      'receipt', () async {
    final stored = [
      for (var i = 0; i < 3; i++) threadReply(i, 100 - i),
      mainMessage(r'$main', 50),
      mainMessage(rootId, 30),
    ];
    when(client.database).thenReturn(_StoredEventsDatabase(stored));
    room.lastEvent = stored.first;

    await room.markRoomAndAllThreadsRead();

    verify(
      client.postReceipt(roomId, ReceiptType.mRead, r'$main', threadId: 'main'),
    ).called(1);
  });

  group('with unread threads', () {
    const rootA = r'$rootA';
    const rootB = r'$rootB';
    const rootRead = r'$rootRead';

    /// Replies of each thread on the server, newest first.
    final repliesOf = <String, List<String>>{
      rootA: [r'$a3', r'$a2', r'$a1'],
      rootB: [r'$b1'],
      rootRead: [r'$r1'],
    };

    MatrixEvent reply(String root, String eventId) => MatrixEvent(
      type: EventTypes.Message,
      content: {
        'msgtype': 'm.text',
        'body': eventId,
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': root,
          'is_falling_back': true,
        },
      },
      senderId: bob,
      eventId: eventId,
      originServerTs: at(60),
    );

    PostExpectation<Future<GetRelatingEventsWithRelTypeResponse>>
    whenRelations({String? root}) => when(
      client.getRelatingEventsWithRelType(
        roomId,
        root ?? any,
        any,
        from: anyNamed('from'),
        to: anyNamed('to'),
        limit: anyNamed('limit'),
        dir: anyNamed('dir'),
        recurse: anyNamed('recurse'),
      ),
    );

    setUp(() {
      final stored = [mainMessage(r'$main', 50), mainMessage(rootA, 30)];
      when(client.database).thenReturn(_StoredEventsDatabase(stored));
      room.lastEvent = stored.first;
      for (final root in repliesOf.keys) {
        whenRelations(root: root).thenAnswer((invocation) async {
          final limit = invocation.namedArguments[#limit] as int?;
          final ids = repliesOf[root]!;
          return GetRelatingEventsWithRelTypeResponse(
            chunk: [
              for (final id in limit == null ? ids : ids.take(limit))
                reply(root, id),
            ],
          );
        });
      }
      client.threadUnread.apply(
        const SyncThreadUpdate(
          counts: {
            roomId: {
              rootA: (notificationCount: 3, highlightCount: 0),
              rootB: (notificationCount: 1, highlightCount: 1),
              rootRead: (notificationCount: 0, highlightCount: 0),
            },
          },
          leftRoomIds: [],
        ),
      );
    });

    test('each unread thread gets a receipt on its newest reply, and the main '
        'timeline its own', () async {
      await room.markRoomAndAllThreadsRead();

      verify(
        client.postReceipt(roomId, ReceiptType.mRead, r'$a3', threadId: rootA),
      ).called(1);
      verify(
        client.postReceipt(roomId, ReceiptType.mRead, r'$b1', threadId: rootB),
      ).called(1);
      verify(
        client.postReceipt(
          roomId,
          ReceiptType.mRead,
          r'$main',
          threadId: 'main',
        ),
      ).called(1);
    });

    test('only the newest reply of each thread is fetched', () async {
      await room.markRoomAndAllThreadsRead();

      for (final root in [rootA, rootB]) {
        final limits = verify(
          client.getRelatingEventsWithRelType(
            roomId,
            root,
            any,
            from: anyNamed('from'),
            to: anyNamed('to'),
            limit: captureAnyNamed('limit'),
            dir: anyNamed('dir'),
            recurse: anyNamed('recurse'),
          ),
        ).captured;
        expect(limits, [1], reason: 'one page of one reply for $root');
      }
    });

    test('a thread already read is neither fetched nor sent a '
        'receipt', () async {
      await room.markRoomAndAllThreadsRead();

      verifyNever(
        client.getRelatingEventsWithRelType(
          any,
          rootRead,
          any,
          from: anyNamed('from'),
          to: anyNamed('to'),
          limit: anyNamed('limit'),
          dir: anyNamed('dir'),
          recurse: anyNamed('recurse'),
        ),
      );
      verifyNever(client.postReceipt(any, any, any, threadId: rootRead));
    });
  });
}

/// A client that keeps the thread counters, like [TwakeClient].
class _ThreadClient extends MockClient implements ThreadUnreadStoreOwner {
  @override
  late final ThreadUnreadStore threadUnread = ThreadUnreadStore(client: this);
}
