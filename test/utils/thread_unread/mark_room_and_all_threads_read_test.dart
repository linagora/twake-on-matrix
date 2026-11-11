import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import 'thread_fakes.dart';

/// THR-M-06 « Marquer comme lu », maintainer decision (11/11), review
/// nqhhdev 4521574499: « Mark as read » sends ONE unthreaded read receipt
/// (no `thread_id`) on the newest event of the room, a thread reply
/// included. MSC3771: an unthreaded receipt covers the main timeline and
/// every thread up to that event, so no thread is fetched (no
/// `/relations`) and no thread gets a receipt of its own. `m.fully_read`
/// stays on the newest main timeline event, as before.
/// https://spec.matrix.org/v1.16/client-server-api/#threaded-read-receipts
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _client = RecordingThreadClient();
    when(_client.clientName).thenReturn('account-a');
    when(_client.userID).thenReturn(_me);
    when(_client.receiptsPublicByDefault).thenReturn(true);
    when(
      _client.roomPreviewLastEvents,
    ).thenReturn({EventTypes.Message, EventTypes.Encrypted});
    _room = Room(id: _roomId, client: _client);
    when(_client.getRoomById(_roomId)).thenReturn(_room);
  });

  group('the newest event is a thread reply', _newestIsReplyTests);
  group('the newest event is a main message', _newestIsMainTests);
  group('with unread threads', _unreadThreadsTests);
}

const _roomId = '!room:example.com';
const _rootId = r'$root';
const _me = '@me:example.com';
const _bob = '@bob:example.com';

late RecordingThreadClient _client;
late Room _room;

DateTime _at(int minute) =>
    DateTime.utc(2026, 11, 6, 10).add(Duration(minutes: minute));

Event _threadReply(int i, int minute, {String root = _rootId}) => Event(
  type: EventTypes.Message,
  content: {
    'msgtype': 'm.text',
    'body': 'reply $i',
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': root,
      'is_falling_back': true,
    },
  },
  eventId: '\$thread_reply_$i',
  senderId: _bob,
  originServerTs: _at(minute),
  room: _room,
);

Event _mainMessage(
  String eventId,
  int minute, {
  EventStatus status = EventStatus.synced,
}) => Event(
  type: EventTypes.Message,
  content: {'msgtype': 'm.text', 'body': 'main $eventId'},
  eventId: eventId,
  senderId: _bob,
  originServerTs: _at(minute),
  room: _room,
  status: status,
);

/// The stored events, newest first. The room's last event is its newest
/// main message, as the app keeps it (a thread reply is not a preview).
void _store(List<Event> newestFirst, {Event? lastEvent}) {
  when(_client.database).thenReturn(StoredEvents(newestFirst));
  _room.lastEvent = lastEvent;
}

SentReceipt _unthreaded(String eventId, {bool public = true}) =>
    (eventId: eventId, threadId: null, public: public);

void _newestIsReplyTests() {
  /// Newest first: 40 replies in a busy thread, then the last message of
  /// the main timeline, then older history.
  void storeBusyThread() {
    final main = _mainMessage(r'$main', 50);
    _store([
      for (var i = 0; i < 40; i++) _threadReply(i, 100 - i),
      main,
      _mainMessage(r'$older_main', 40),
      _mainMessage(_rootId, 30),
    ], lastEvent: main);
  }

  test('one unthreaded receipt on the newest reply reads the room and its '
      'threads', () async {
    storeBusyThread();

    await _room.markRoomAndAllThreadsRead();

    expect(_client.receipts, [_unthreaded(r'$thread_reply_0')]);
  });

  test('m.fully_read lands on the main message hidden behind 40 thread '
      'replies', () async {
    storeBusyThread();

    await _room.markRoomAndAllThreadsRead();

    expect(_client.fullyRead, [r'$main']);
  });

  test('a room whose stored events are all thread replies: the receipt '
      'lands on the newest one, m.fully_read does not move', () async {
    _store([_threadReply(1, 20), _threadReply(0, 10)]);

    await _room.markRoomAndAllThreadsRead();

    expect(_client.receipts, [_unthreaded(r'$thread_reply_1')]);
    expect(_client.fullyRead, isEmpty);
  });
}

void _newestIsMainTests() {
  test('the receipt and m.fully_read both land on it', () async {
    final main = _mainMessage(r'$main', 50);
    _store([
      main,
      _threadReply(0, 40),
      _mainMessage(_rootId, 30),
    ], lastEvent: main);

    await _room.markRoomAndAllThreadsRead();

    expect(_client.receipts, [_unthreaded(r'$main')]);
    expect(_client.fullyRead, [r'$main']);
  });

  test('a message still being sent is not read: the receipt lands on the '
      'newest event the server has', () async {
    final main = _mainMessage(r'$main', 50);
    _store([
      _mainMessage('txn-1', 60, status: EventStatus.sending),
      _threadReply(0, 55),
      main,
    ], lastEvent: main);

    await _room.markRoomAndAllThreadsRead();

    expect(_client.receipts, [_unthreaded(r'$thread_reply_0')]);
    expect(_client.fullyRead, [r'$main']);
  });

  test('with private receipts, the one receipt is private', () async {
    when(_client.receiptsPublicByDefault).thenReturn(false);
    final main = _mainMessage(r'$main', 50);
    _store([_threadReply(0, 60), main], lastEvent: main);

    await _room.markRoomAndAllThreadsRead();

    expect(_client.receipts, [_unthreaded(r'$thread_reply_0', public: false)]);
  });

  test('an empty room sends nothing', () async {
    _store(const []);

    await _room.markRoomAndAllThreadsRead();

    expect(_client.receipts, isEmpty);
    expect(_client.fullyRead, isEmpty);
  });
}

/// `GET /relations/<root>/m.thread` of any thread (a mock call matcher).
Future<GetRelatingEventsWithRelTypeResponse> _threadRelationsRequest() =>
    _client.getRelatingEventsWithRelType(
      any,
      any,
      any,
      from: anyNamed('from'),
      to: anyNamed('to'),
      limit: anyNamed('limit'),
      dir: anyNamed('dir'),
      recurse: anyNamed('recurse'),
    );

void _unreadThreadsTests() {
  const rootA = r'$rootA';
  const rootB = r'$rootB';

  setUp(() {
    final main = _mainMessage(r'$main', 50);
    _store([main, _mainMessage(rootA, 30)], lastEvent: main);
    // The server has replies: a per-thread lookup would find one.
    when(_threadRelationsRequest()).thenAnswer(
      (_) async => GetRelatingEventsWithRelTypeResponse(
        chunk: [_threadReply(9, 45, root: rootA)],
      ),
    );
    _client.threadUnread.apply(
      const SyncThreadUpdate(
        counts: {
          _roomId: {
            rootA: (notificationCount: 3, highlightCount: 0),
            rootB: (notificationCount: 1, highlightCount: 1),
          },
        },
        leftRoomIds: [],
      ),
    );
  });

  test('no thread is fetched: no /relations request', () async {
    await _room.markRoomAndAllThreadsRead();

    verifyNever(_threadRelationsRequest());
    verifyNever(
      _client.getRelatingEvents(
        any,
        any,
        from: anyNamed('from'),
        to: anyNamed('to'),
        limit: anyNamed('limit'),
        dir: anyNamed('dir'),
        recurse: anyNamed('recurse'),
      ),
    );
  });

  test('no thread gets a receipt of its own: the one unthreaded receipt '
      'covers them', () async {
    await _room.markRoomAndAllThreadsRead();

    expect(_client.receipts, [_unthreaded(r'$main')]);
  });
}
