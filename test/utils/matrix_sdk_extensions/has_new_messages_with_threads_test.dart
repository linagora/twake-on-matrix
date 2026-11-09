import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../fake_client.dart';

/// THR-M-06, spec §4 « Reçus ».
///
/// The app sends threaded receipts only (`thread_id: main` or the
/// root id), so the unthreaded `receiptState.global` of an account that used
/// an older client stays on an old event. The SDK `Room.hasNewMessages` reads
/// that stale global receipt and reports new messages forever.
///
/// THR-M-06 badge rule: a reply of a thread the user does not follow counts
/// only on its card, unless it mentions the user.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _client = _ThreadClient();
    when(_client.clientName).thenReturn('account-a');
    when(_client.userID).thenReturn(_me);
    // Event.receipts of the SDK looks the user up in the database.
    when(_client.database).thenReturn(MockDatabase());
    when(
      _client.roomPreviewLastEvents,
    ).thenReturn({EventTypes.Message, EventTypes.Encrypted});
  });

  group(
    'a stale unthreaded receipt does not keep the room unread',
    _staleReceiptTests,
  );
  group('new messages are still reported', _newMessagesTests);
  group('a reply in a thread the user does not follow', _notFollowedTests);

  /// THR-M-09, MSC3771: an own receipt with `thread_id: main` reads the main
  /// timeline only. A thread reply is read by the receipt of its thread or
  /// by an unthreaded one, never by a `main` one, however recent.
  group('the last event is a reply of a followed thread', _followedReplyTests);
  group(
    'a reply of a followed thread without a server counter',
    _followedWithoutCounterTests,
  );
  group('rules kept from the SDK', _sdkRulesTests);
}

const _roomId = '!room:example.com';
const _me = '@me:example.com';
const _bob = '@bob:example.com';
const _rootId = r'$root';

late _ThreadClient _client;

DateTime _at(int minute) => DateTime.utc(2026, 11, 6, 10, minute);

LatestReceiptStateData _receipt(String eventId, int minute) =>
    LatestReceiptStateData(eventId, _at(minute).millisecondsSinceEpoch);

/// The receipt the user has before the last event of the room.
final _readBefore = _receipt(r'$before', 1);

LatestReceiptStateForTimeline _own(LatestReceiptStateData data) =>
    LatestReceiptStateForTimeline(
      ownPrivate: null,
      ownPublic: data,
      latestOwnReceipt: data,
      otherUsers: {},
    );

/// An account that used an unthreaded client long ago: its global receipt
/// is on an event of last week and never moves again.
LatestReceiptStateForTimeline _staleGlobal() => _own(
  LatestReceiptStateData(
    r'$old',
    DateTime.utc(2026, 10, 30).millisecondsSinceEpoch,
  ),
);

/// The receipts of such an account: [main] on the main timeline, [threads]
/// by thread root.
LatestReceiptState _staleAnd(
  LatestReceiptStateData main, {
  Map<String, LatestReceiptStateData> threads = const {},
}) => LatestReceiptState(
  global: _staleGlobal(),
  mainThread: _own(main),
  byThread: threads.map((root, data) => MapEntry(root, _own(data))),
);

/// Receipts of a client of the account that still sends unthreaded ones.
LatestReceiptState _unthreadedOn(LatestReceiptStateData global) =>
    LatestReceiptState(global: _own(global), mainThread: _own(_readBefore));

/// Server counters of the thread [root], and whether the user follows it.
void _threadCounters(
  String root, {
  required bool followed,
  int notifications = 1,
  int highlights = 0,
}) {
  _client.threadUnread.apply(
    SyncThreadUpdate(
      counts: {
        _roomId: {
          root: (notificationCount: notifications, highlightCount: highlights),
        },
      },
      leftRoomIds: const [],
    ),
  );
  if (followed) _client.threadUnread.markFollowed(ThreadRef(_roomId, root));
}

Map<String, Object?> _threadRelation(String root) => {
  'rel_type': RelationshipTypes.thread,
  'event_id': root,
  'is_falling_back': true,
};

Room _roomWith({
  required LatestReceiptState receipts,
  Event Function(Room room) lastEvent = _message,
}) {
  final room = Room(id: _roomId, client: _client, receiptState: receipts);
  room.lastEvent = lastEvent(room);
  return room;
}

Event _message(
  Room room, {
  String eventId = r'$last',
  String sender = _bob,
  String type = EventTypes.Message,
  Map<String, Object?>? relatesTo,
}) => Event(
  type: type,
  content: {'msgtype': 'm.text', 'body': 'hello', 'm.relates_to': ?relatesTo},
  eventId: eventId,
  senderId: sender,
  originServerTs: _at(5),
  room: room,
);

/// A reply of the thread of [_rootId], sent at minute 5.
Event _reply(Room room) =>
    _message(room, eventId: r'$reply', relatesTo: _threadRelation(_rootId));

/// A room whose last event is [_reply].
Room _roomWithLastReply(LatestReceiptState receipts) =>
    _roomWith(receipts: receipts, lastEvent: _reply);

void _staleReceiptTests() {
  test('a main receipt on the last event reads the room', () {
    final room = _roomWith(receipts: _staleAnd(_receipt(r'$last', 6)));

    // The hostile condition: the SDK is fooled by the stale global receipt.
    expect(room.hasNewMessages, isTrue);
    expect(room.hasNewMessagesWithThreads, isFalse);
  });

  test('a main receipt newer than the last event reads the room, even on '
      'another event', () {
    // The receipt is on an event the client does not show (a reaction, an
    // edit) but it came after the last message.
    final room = _roomWith(receipts: _staleAnd(_receipt(r'$other', 7)));

    expect(room.hasNewMessagesWithThreads, isFalse);
  });

  test('a thread reply read in its thread reads the room', () {
    _threadCounters(_rootId, followed: true, notifications: 0);
    final room = _roomWithLastReply(
      _staleAnd(_readBefore, threads: {_rootId: _receipt(r'$reply', 6)}),
    );

    expect(room.hasNewMessagesWithThreads, isFalse);
  });
  test('an unthreaded receipt on the last event still reads the room', () {
    // A client of the account that still sends unthreaded receipts.
    final room = _roomWith(receipts: _unthreadedOn(_receipt(r'$last', 6)));

    expect(room.hasNewMessagesWithThreads, isFalse);
  });
}

void _newMessagesTests() {
  test('a main receipt older than the last event leaves the room unread', () {
    final room = _roomWith(receipts: _staleAnd(_readBefore));

    expect(room.hasNewMessagesWithThreads, isTrue);
  });

  test('a room without any receipt of the user is unread', () {
    final room = _roomWith(receipts: LatestReceiptState.empty());

    expect(room.hasNewMessagesWithThreads, isTrue);
  });

  test('a receipt in another thread does not read a reply of a followed '
      'thread', () {
    _threadCounters(_rootId, followed: true);
    final room = _roomWithLastReply(
      _staleAnd(
        _readBefore,
        threads: {r'$another_root': _receipt(r'$elsewhere', 9)},
      ),
    );

    expect(room.hasNewMessagesWithThreads, isTrue);
  });
}

void _notFollowedTests() {
  // Read up to before the reply, everywhere.
  Room roomWithUnreadReply() => _roomWithLastReply(
    _staleAnd(_readBefore, threads: {_rootId: _receipt(r'$older_reply', 2)}),
  );

  test('is not a new message of the room', () {
    _threadCounters(_rootId, followed: false);

    expect(roomWithUnreadReply().hasNewMessagesWithThreads, isFalse);
  });

  test('is not a new message of the room in an E2EE room, while it cannot '
      'be decrypted', () {
    // `m.relates_to` stays in clear on `m.room.encrypted`.
    _threadCounters(_rootId, followed: false);
    final room = _roomWith(
      receipts: _staleAnd(_readBefore),
      lastEvent: (room) => Event(
        type: EventTypes.Encrypted,
        content: {
          'algorithm': 'm.megolm.v1.aes-sha2',
          'ciphertext': 'AwgA',
          'session_id': 'unknown',
          'm.relates_to': _threadRelation(_rootId),
        },
        eventId: r'$reply',
        senderId: _bob,
        originServerTs: _at(5),
        room: room,
      ),
    );

    expect(room.hasNewMessagesWithThreads, isFalse);
  });

  test('that mentions the user is a new message of the room', () {
    _threadCounters(_rootId, followed: false, highlights: 1);

    expect(roomWithUnreadReply().hasNewMessagesWithThreads, isTrue);
  });

  test('is a new message once the user follows the thread', () {
    _threadCounters(_rootId, followed: true);

    expect(roomWithUnreadReply().hasNewMessagesWithThreads, isTrue);
  });
}

/// CodeRabbit 4515561997: Synapse sends counters only for threads with a
/// non-zero count; in a "mentions only" room a plain reply makes none.
void _followedWithoutCounterTests() {
  test('is a new message of the room', () {
    _client.threadUnread.markFollowed(const ThreadRef(_roomId, _rootId));

    expect(
      _roomWithLastReply(_staleAnd(_readBefore)).hasNewMessagesWithThreads,
      isTrue,
    );
  });
}

void _followedReplyTests() {
  setUp(() => _threadCounters(_rootId, followed: true));

  final mainAfter = _receipt(r'$main_after', 7);

  test('a newer own main receipt does not read it: the room still has new '
      'messages', () {
    final room = _roomWithLastReply(_staleAnd(mainAfter));

    expect(room.hasNewMessagesWithThreads, isTrue);
  });

  test('a newer own main receipt and an older receipt of the thread: the '
      'room still has new messages', () {
    final room = _roomWithLastReply(
      _staleAnd(mainAfter, threads: {_rootId: _receipt(r'$older_reply', 2)}),
    );

    expect(room.hasNewMessagesWithThreads, isTrue);
  });

  test('a newer own receipt of the thread reads it', () {
    final room = _roomWithLastReply(
      _staleAnd(mainAfter, threads: {_rootId: _receipt(r'$reply', 6)}),
    );

    expect(room.hasNewMessagesWithThreads, isFalse);
  });

  test('a newer unthreaded own receipt reads it', () {
    // A client of the account that still sends unthreaded receipts.
    final room = _roomWithLastReply(_unthreadedOn(_receipt(r'$reply', 6)));

    expect(room.hasNewMessagesWithThreads, isFalse);
  });
}

void _sdkRulesTests() {
  LatestReceiptState stale() => LatestReceiptState(global: _staleGlobal());

  test('the last event sent by the user is not a new message', () {
    final room = _roomWith(
      receipts: stale(),
      lastEvent: (room) => _message(room, sender: _me),
    );

    expect(room.hasNewMessagesWithThreads, isFalse);
  });

  test('a last event of a type not shown in the preview is not a new '
      'message', () {
    final room = _roomWith(
      receipts: stale(),
      lastEvent: (room) => _message(room, type: EventTypes.RoomMember),
    );

    expect(room.hasNewMessagesWithThreads, isFalse);
  });

  test('a room without last event has no new message', () {
    final room = Room(id: _roomId, client: _client, receiptState: stale());

    expect(room.hasNewMessagesWithThreads, isFalse);
  });
}

/// A client that keeps the thread counters, like [TwakeClient].
class _ThreadClient extends MockClient implements ThreadUnreadStoreOwner {
  @override
  late final ThreadUnreadStore threadUnread = ThreadUnreadStore(client: this);
}
