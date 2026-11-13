import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_resolved.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_resolved.dart';

import '../../../fake_client.dart';

/// THR-M-08 and spec § 4 « Fil résolu » / « Droit de résoudre » (D56): the
/// state event `app.twake.chat.thread_resolved`, state key = id of the root,
/// content `{ "resolved": true }` (`false` reopens). Only who may send that
/// state sees « Mark as resolved »: `canChangeStateEvent` falls back on
/// `state_default`, not on `events_default` like `canSendEvent`.
void main() {
  test('the state type is the one of the web', () {
    expect(threadResolvedStateType, 'app.twake.chat.thread_resolved');
  });

  group('a thread is resolved', _resolvedTests);
  group('who may resolve a thread', _permissionTests);
}

const _me = '@me:example.org';
const _rootId = r'$lunch';

class _Account extends Client {
  _Account() : super('thread-resolved-test', database: MockDatabase());

  @override
  String? get userID => _me;
}

Room _joinedRoom() => Room(
  id: '!team:example.org',
  client: _Account(),
  membership: Membership.join,
);

/// [state] lands in [room], sent by [_me].
void _put(Room room, StrippedStateEvent state) => room.setState(
  Event(
    type: state.type,
    content: state.content,
    eventId: '\$state_${room.states.length}',
    senderId: _me,
    stateKey: state.stateKey,
    originServerTs: DateTime.utc(2026, 11, 10),
    room: room,
  ),
);

/// The resolved state of a thread, with the content [content].
StrippedStateEvent _resolvedState(
  Map<String, Object?> content, {
  ThreadRoot root = ThreadRoot.lunch,
}) => StrippedStateEvent(
  type: 'app.twake.chat.thread_resolved',
  content: content,
  senderId: _me,
  stateKey: root.id,
);

/// The roots of the threads of the room.
enum ThreadRoot {
  lunch(_rootId),
  release(r'$release');

  const ThreadRoot(this.id);

  final String id;
}

Room _roomWithState(StrippedStateEvent state) {
  final room = _joinedRoom();
  _put(room, state);
  return room;
}

/// A room whose power levels are [levels].
Room _roomWith(Map<String, Object?> levels) => _roomWithState(
  StrippedStateEvent(
    type: EventTypes.RoomPowerLevels,
    content: levels,
    senderId: _me,
    stateKey: '',
  ),
);

void _resolvedTests() {
  test('when the root has the state with resolved true', () {
    final room = _roomWithState(_resolvedState({'resolved': true}));

    expect(room.isThreadResolved(_rootId), isTrue);
  });

  test('not when it was reopened (resolved false)', () {
    final room = _roomWithState(_resolvedState({'resolved': false}));

    expect(room.isThreadResolved(_rootId), isFalse);
  });

  test('not when nobody ever resolved it', () {
    expect(_joinedRoom().isThreadResolved(_rootId), isFalse);
  });

  test('not when another thread of the room is resolved', () {
    final room = _roomWithState(
      _resolvedState({'resolved': true}, root: ThreadRoot.release),
    );

    expect(room.isThreadResolved(_rootId), isFalse);
  });

  test('not when the content is not a boolean', () {
    final room = _roomWithState(_resolvedState({'resolved': 'yes'}));

    expect(room.isThreadResolved(_rootId), isFalse);
  });
}

void _permissionTests() {
  test('a member who may send messages but not states may not', () {
    final room = _roomWith({
      'users': {_me: 0},
      'events_default': 0,
      'state_default': 50,
    });

    expect(room.canResolveThreads, isFalse);
  });

  test('a member allowed by the level of the thread state may', () {
    final room = _roomWith({
      'users': {_me: 0},
      'state_default': 50,
      'events': {'app.twake.chat.thread_resolved': 0},
    });

    expect(room.canResolveThreads, isTrue);
  });

  test('a moderator may, by the default level of states', () {
    final room = _roomWith({
      'users': {_me: 50},
      'state_default': 50,
    });

    expect(room.canResolveThreads, isTrue);
  });

  test('nobody may in a room they have not joined', () {
    final room = Room(
      id: '!team:example.org',
      client: _Account(),
      membership: Membership.invite,
    );

    expect(room.canResolveThreads, isFalse);
  });
}
