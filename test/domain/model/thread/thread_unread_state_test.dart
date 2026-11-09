import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';

/// Spec §5 « Compteurs par fil »: the thread counters are saved per account
/// and found again after a restart. The saved JSON is data already on the
/// devices: what the app wrote before the typed store must still restore.
void main() {
  group('saved thread counters', _savedCounters);
  group('a sync of the threads', _syncUpdate);
  group('a thread', _threadIdentity);
}

const _roomId = '!room:example.com';
const _otherRoomId = '!other:example.com';
const _rootId = r'$root';

/// What the store saved before the typed ids (its old `_toJson`), written
/// by hand: counts as [notification, highlight], follows as `room|root`.
const _savedBefore =
    '{"counts":{"$_roomId":{"$_rootId":[3,1]}},'
    '"followed":["$_roomId|$_rootId"],'
    '"replies":{"$_roomId":["\$reply1","\$reply2"]}}';

ThreadUnreadSnapshot _decode(String raw) =>
    ThreadUnreadSnapshot.fromJson(jsonDecode(raw) as Map<String, Object?>);

/// Through the JSON text, as the device storage holds it.
ThreadUnreadSnapshot _saveAndReload(ThreadUnreadSnapshot snapshot) =>
    _decode(jsonEncode(snapshot.toJson()));

void _savedCounters() {
  test('the format saved before the typed store restores every counter, '
      'follow and reply id', () {
    final restored = _decode(_savedBefore);

    expect(restored.counts, {
      _roomId: {_rootId: (notificationCount: 3, highlightCount: 1)},
    });
    expect(restored.followed, {const ThreadRef(_roomId, _rootId)});
    expect(restored.replies, {
      _roomId: {r'$reply1', r'$reply2'},
    });
  });

  test('are written in the format saved before the typed store', () {
    expect(_decode(_savedBefore).toJson(), jsonDecode(_savedBefore));
  });

  test('are found again after a save and a reload', () {
    // Not const: a const set cannot hold an Equatable ThreadRef.
    final snapshot = ThreadUnreadSnapshot(
      counts: const {
        _roomId: {_rootId: (notificationCount: 2, highlightCount: 0)},
        _otherRoomId: {
          r'$other_root': (notificationCount: 5, highlightCount: 4),
        },
      },
      followed: {
        const ThreadRef(_roomId, _rootId),
        const ThreadRef(_otherRoomId, r'$x'),
      },
      replies: const {
        _roomId: {r'$reply1'},
      },
    );

    final restored = _saveAndReload(snapshot);

    expect(restored.counts, snapshot.counts);
    expect(restored.followed, snapshot.followed);
    expect(restored.replies, snapshot.replies);
  });

  test('a room without remembered reply is not written', () {
    const snapshot = ThreadUnreadSnapshot(
      counts: {},
      followed: {},
      replies: {_roomId: {}},
    );

    expect(_saveAndReload(snapshot).replies, isEmpty);
  });

  test('nothing saved yet restores nothing', () {
    final restored = ThreadUnreadSnapshot.fromJson(const {});

    expect(restored.counts, isEmpty);
    expect(restored.followed, isEmpty);
    expect(restored.replies, isEmpty);
  });
}

void _syncUpdate() {
  test('names each room with its counters, and the rooms left', () {
    const update = SyncThreadUpdate(
      counts: {
        _roomId: {_rootId: (notificationCount: 1, highlightCount: 0)},
      },
      leftRoomIds: [_otherRoomId],
    );

    final rooms = update.rooms.toList();
    expect(rooms, hasLength(1));
    expect(rooms.single.id.value, _roomId);
    expect(rooms.single.threads, update.counts[_roomId]);
    expect(update.leftRooms.map((room) => room.value), [_otherRoomId]);
    expect(update.hasLeft, isTrue);
  });

  test('without a room left, says so', () {
    const update = SyncThreadUpdate(counts: {}, leftRoomIds: []);

    expect(update.hasLeft, isFalse);
    expect(update.rooms, isEmpty);
  });
}

void _threadIdentity() {
  test('is the same thread for the same room and root', () {
    // Built at run time: another instance, not the const one.
    final root = String.fromCharCodes(_rootId.codeUnits);
    final sameThread = ThreadRef(_roomId, root);

    final threads = {const ThreadRef(_roomId, _rootId)};

    expect(threads, contains(sameThread));
    expect(sameThread.hashCode, const ThreadRef(_roomId, _rootId).hashCode);
  });

  test('differs by its room or by its root', () {
    const thread = ThreadRef(_roomId, _rootId);

    expect(thread, isNot(const ThreadRef(_otherRoomId, _rootId)));
    expect(thread, isNot(const ThreadRef(_roomId, r'$other_root')));
  });
}
