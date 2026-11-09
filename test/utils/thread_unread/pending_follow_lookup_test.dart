// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../fake_client.dart' as fake;

/// Review 4515300531 (the race) and 4515300560.
///
/// A sync raises the counter of a thread and starts the follow lookup; the
/// same sync then clears the notifications of every room whose badge is 0.
/// While the lookup runs the badge of a thread not known as followed is 0
/// because the answer is unknown, not because the reply was read: the
/// notification of a reply in a thread the user replied to was cancelled.
/// While a lookup runs for a room with unread replies, its notifications
/// stay.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _lookup = Completer<MatrixEvent>();
    _client = _ThreadClient();
    when(_client.clientName).thenReturn('account-a');
    when(_client.userID).thenReturn(_me);
    when(_client.database).thenReturn(_NoStoredRoot());
    when(
      _client.getOneRoomEvent(_roomId, _rootId),
    ).thenAnswer((_) => _lookup.future);
    _room = Room(id: _roomId, client: _client);
    when(_client.getRoomById(_roomId)).thenReturn(_room);
  });

  group('a follow lookup pending for a room', _pendingLookupTests);
  group('the notifications of a room may be cleared', _clearRuleTests);
}

const _roomId = '!room:example.com';
const _otherRoomId = '!other:example.com';
const _rootId = r'$root';
const _me = '@me:example.com';

late _ThreadClient _client;
late Room _room;

/// What `GET /rooms/{roomId}/event/{rootId}` will answer.
late Completer<MatrixEvent> _lookup;

ThreadUnreadStore get _store => _client.threadUnread;

/// A sync carrying [replies] unread replies (no mention) in the thread.
void _sync(int replies, {String roomId = _roomId}) => _store.apply(
  SyncThreadUpdate(
    counts: {
      roomId: {_rootId: (notificationCount: replies, highlightCount: 0)},
    },
    leftRoomIds: const [],
  ),
);

/// The server answers the lookup.
Future<void> _answer({required bool participated}) async {
  _lookup.complete(
    MatrixEvent(
      type: EventTypes.Message,
      content: {'msgtype': 'm.text', 'body': 'root'},
      eventId: _rootId,
      senderId: '@alice:example.com',
      originServerTs: DateTime.utc(2026, 11, 9),
      roomId: _roomId,
      unsigned: {
        'm.relations': {
          'm.thread': {'count': 2, 'current_user_participated': participated},
        },
      },
    ),
  );
  await pumpEventQueue();
}

bool get _pending => _store.hasPendingFollowLookup(_room);

void _pendingLookupTests() {
  test('nothing pending before any sync', () {
    expect(_pending, isFalse);
  });

  test('a new unread reply starts a lookup: pending', () async {
    _sync(1);
    await pumpEventQueue();

    expect(_pending, isTrue);
  });

  test('the server says the user participated: no longer pending', () async {
    _sync(1);
    await _answer(participated: true);

    expect(_pending, isFalse);
  });

  test('the server says not participated: no longer pending', () async {
    _sync(1);
    await _answer(participated: false);

    expect(_pending, isFalse);
  });

  test('the lookup fails: no longer pending', () async {
    _sync(1);
    _lookup.completeError(MatrixException.fromJson({'errcode': 'M_UNKNOWN'}));
    await pumpEventQueue();

    expect(_pending, isFalse);
  });

  test('a thread already followed starts no lookup', () async {
    _store.markFollowed(const ThreadRef(_roomId, _rootId));
    _sync(1);
    await pumpEventQueue();

    expect(_pending, isFalse);
  });

  test('the replies read meanwhile: not pending, although the lookup still '
      'runs', () async {
    _sync(1);
    await pumpEventQueue();
    _sync(0);

    expect(_pending, isFalse);
  });

  test('a lookup for a thread of another room is not pending here', () async {
    when(
      _client.getOneRoomEvent(_otherRoomId, _rootId),
    ).thenAnswer((_) => Completer<MatrixEvent>().future);
    _sync(1, roomId: _otherRoomId);
    await pumpEventQueue();

    expect(_pending, isFalse);
  });
}

void _clearRuleTests() {
  test('a badge of 0 and nothing pending: may be cleared', () {
    expect(_room.hasNoPendingNotification, isTrue);
  });

  test('a badge of 0 while a lookup is pending: kept', () async {
    _sync(1);
    await pumpEventQueue();

    expect(_room.unreadBadgeCount, 0);
    expect(_room.hasNoPendingNotification, isFalse);
  });

  test('the lookup said not followed: may be cleared', () async {
    _sync(1);
    await _answer(participated: false);

    expect(_room.hasNoPendingNotification, isTrue);
  });

  test('the lookup said followed: kept (the badge counts the reply)', () async {
    _sync(1);
    await _answer(participated: true);

    expect(_room.hasNoPendingNotification, isFalse);
  });

  test('an unread main message: kept', () {
    final room = Room(id: _roomId, client: _client, notificationCount: 1);

    expect(room.hasNoPendingNotification, isFalse);
  });

  test('a left room may be cleared, also while a lookup is pending', () async {
    _sync(1);
    await pumpEventQueue();
    final left = Room(
      id: _roomId,
      client: _client,
      membership: Membership.leave,
      notificationCount: 3,
    );

    expect(left.hasNoPendingNotification, isTrue);
  });
}

class _ThreadClient extends MockClient implements ThreadUnreadStoreOwner {
  @override
  late final ThreadUnreadStore threadUnread = ThreadUnreadStore(client: this);
}

/// The device database does not hold the root: the server is asked.
class _NoStoredRoot extends fake.MockDatabase {
  @override
  Future<Event?> getEventById(String eventId, Room room) async => null;
}
