// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/space_child.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/data/datasource_impl/spaces/room_list_entry_mapper.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../../domain/usecase/room/send_text_message_interactor_test.mocks.dart'
    show MockRoom;
import '../../../utils/thread_unread/thread_fakes.dart';

/// Review of #3608 (nqhhdev, blocking, +1 jbrnzl): with
/// `unread_thread_notifications` in the sync filter the server leaves the
/// thread replies out of the room counters. The room list (Unread folder,
/// space counters) reads the same thread-aware counters as the chat list:
/// replies of a followed thread (participation, P1) and mentions of any
/// thread count for the room.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool flagBefore;

  setUp(() {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    SharedPreferences.setMockInitialValues({});
    _client = RecordingThreadClient();
    when(_client.clientName).thenReturn('account-a');
    when(_client.userID).thenReturn(_me);
    when(_client.database).thenReturn(StoredEvents(const []));
    when(
      _client.getOneRoomEvent(any, any),
    ).thenAnswer((call) async => _rootNotParticipated(call));
  });

  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  group('a room of the room list', _entryCountTests);
  group('the Unread folder', _unreadFolderTests);
  group('a folded space', _spaceCountTests);
  group('with threads off', _threadsOffTests);
  group('a muted thread', _mutedTests);
  group('an explicit follow choice', _followChoiceTests);
}

const _roomId = '!room:example.com';
const _spaceId = '!space:example.com';
const _rootId = r'$root';
const _me = '@me:example.com';

late RecordingThreadClient _client;

ThreadUnreadStore get _store => _client.threadUnread;

/// The root as `GET /rooms/{roomId}/event/{rootId}` returns it: the user
/// neither wrote it nor replied.
MatrixEvent _rootNotParticipated(Invocation call) => MatrixEvent(
  type: EventTypes.Message,
  content: {'msgtype': 'm.text', 'body': 'root'},
  eventId: call.positionalArguments[1] as String,
  senderId: '@alice:example.com',
  originServerTs: DateTime.utc(2026, 11, 12),
  roomId: call.positionalArguments[0] as String,
  unsigned: {
    'm.relations': {
      'm.thread': {'count': 3, 'current_user_participated': false},
    },
  },
);

/// Unread messages and mentions: of the room as the server counts them, or
/// of its thread.
typedef _Counts = ({int unread, int mentions});

const _Counts _none = (unread: 0, mentions: 0);

/// The room [_roomId], joined, in no space.
MockRoom _room([_Counts server = _none]) {
  final room = MockRoom();
  when(room.id).thenReturn(_roomId);
  when(room.client).thenReturn(_client);
  when(room.membership).thenReturn(Membership.join);
  when(room.isSpace).thenReturn(false);
  when(room.tags).thenReturn({});
  when(room.spaceParents).thenReturn([]);
  when(room.spaceChildren).thenReturn([]);
  when(room.notificationCount).thenReturn(server.unread);
  when(room.highlightCount).thenReturn(server.mentions);
  return room;
}

/// The space [_spaceId], which lists [_roomId].
MockRoom _space() {
  final space = _room();
  when(space.id).thenReturn(_spaceId);
  when(space.isSpace).thenReturn(true);
  when(space.spaceChildren).thenReturn([
    SpaceChild.fromState(
      StrippedStateEvent(
        type: EventTypes.SpaceChild,
        senderId: '@a:example.com',
        stateKey: _roomId,
        content: {
          'via': ['example.com'],
        },
      ),
    ),
  ]);
  return space;
}

/// The user replied in the thread of [_roomId] (P1: participation is
/// following).
void _followThread() => _store.markFollowed(const ThreadRef(_roomId, _rootId));

/// What a sync says of the thread of [_roomId].
void _threadCounters(_Counts thread) => _store.apply(
  SyncThreadUpdate(
    counts: {
      _roomId: {
        _rootId: (
          notificationCount: thread.unread,
          highlightCount: thread.mentions,
        ),
      },
    },
    leftRoomIds: const [],
  ),
);

/// The thread got replies; the server says the user does not take part.
Future<void> _notFollowedThread(_Counts thread) async {
  _threadCounters(thread);
  await pumpEventQueue();
  expect(
    await _store.followOnceKnown(const ThreadRef(_roomId, _rootId)),
    isFalse,
    reason: 'setup: the lookup answered "not participated"',
  );
}

RoomListEntry _entryOf(Room room) =>
    roomListEntriesOf([room], directChats: const {}).single;

void _entryCountTests() {
  test('a room whose only unread is a followed thread shows its replies', () {
    final room = _room();
    _followThread();
    _threadCounters((unread: 2, mentions: 0));

    final entry = _entryOf(room);

    expect(entry.unreadCount, 2);
    expect(entry.isUnread, isTrue);
  });

  test('main timeline and followed thread unreads add up', () {
    final room = _room((unread: 1, mentions: 0));
    _followThread();
    _threadCounters((unread: 2, mentions: 0));

    expect(_entryOf(room).unreadCount, 3);
  });

  test('a mention in a thread is a mention of the room', () async {
    final room = _room();
    await _notFollowedThread((unread: 1, mentions: 1));

    final entry = _entryOf(room);

    expect(entry.mentionCount, 1);
    expect(entry.unreadCount, 1);
  });

  test('mentions of the room and of its threads add up', () {
    final room = _room((unread: 1, mentions: 1));
    _followThread();
    _threadCounters((unread: 2, mentions: 1));

    expect(_entryOf(room).mentionCount, 2);
  });

  // Guard: green before the fix too; it must stay green after it.
  test(
    'replies of a thread the user does not follow are not counted',
    () async {
      final room = _room();
      await _notFollowedThread((unread: 4, mentions: 0));

      final entry = _entryOf(room);

      expect(entry.unreadCount, 0);
      expect(entry.mentionCount, 0);
      expect(entry.isUnread, isFalse);
    },
  );
}

/// Ids the Unread folder shows when the account holds the room only.
List<String> _unreadFolderIds() => visibleEntries(
  roomListEntriesOf([_room()], directChats: const {}),
  view: const RoomListFilter.builtin(BuiltinFolder.unread),
).map((entry) => entry.id).toList();

/// The row of the space, folded, holding the room.
RoomListSpaceRow _foldedSpaceRow() => buildRoomListRows(
  roomListEntriesOf([_space(), _room()], directChats: const {}),
  foldedSpaceIds: {_spaceId},
).whereType<RoomListSpaceRow>().single;

void _unreadFolderTests() {
  test('keeps a room whose only unread is a followed thread', () {
    _followThread();
    _threadCounters((unread: 1, mentions: 0));

    expect(_unreadFolderIds(), [_roomId]);
  });

  test('keeps a room whose only unread is a thread mention', () async {
    await _notFollowedThread((unread: 1, mentions: 1));

    expect(_unreadFolderIds(), [_roomId]);
  });
}

void _spaceCountTests() {
  test('counts a thread mention of a room it holds', () async {
    await _notFollowedThread((unread: 1, mentions: 1));

    expect(_foldedSpaceRow().mentionCount, 1);
  });

  test('counts the followed thread replies of a room it holds', () {
    _followThread();
    _threadCounters((unread: 3, mentions: 0));

    expect(_foldedSpaceRow().unreadCount, 3);
  });
}

/// The flag fully gates this level: off, the room list shows the server
/// room counters only, as before threads.
void _threadsOffTests() {
  setUp(() => AppConfig.threadsEnabled = false);

  // Guard: green before the fix too; it must stay green after it.
  test('the room list shows the server room counters only', () {
    final room = _room((unread: 1, mentions: 0));
    _followThread();
    _threadCounters((unread: 2, mentions: 1));

    final entry = _entryOf(room);

    expect(entry.unreadCount, 1);
    expect(entry.mentionCount, 0);
  });
}

/// The sync brings the choice of the user about the thread of [_roomId] in
/// `app.twake.chat.thread_prefs` (written here or on the web), as it brings
/// any account data.
void _choose(ThreadPref pref) {
  when(_client.accountData).thenReturn({
    threadPrefsAccountDataType: BasicEvent(
      type: threadPrefsAccountDataType,
      content: {
        'threads': [
          {'roomId': _roomId, 'threadId': _rootId, 'pref': pref.name},
        ],
      },
    ),
  });
  _store.refreshPrefs();
}

/// The user took part in the thread of [_roomId], it got replies and a
/// mention, then the user muted it.
void _mutedThreadWithUnread() {
  _followThread();
  _threadCounters((unread: 3, mentions: 1));
  _choose(ThreadPref.mute);
}

/// P2: a muted thread stays followed but counts nothing, mentions included.
void _mutedTests() {
  test('adds nothing to the counters of its room, even when the user took '
      'part in it', () {
    final room = _room();
    _mutedThreadWithUnread();

    final entry = _entryOf(room);

    expect(entry.unreadCount, 0);
    expect(entry.mentionCount, 0);
    expect(entry.isUnread, isFalse);
  });

  test('leaves the unread messages of the main timeline as they are', () {
    final room = _room((unread: 1, mentions: 1));
    _mutedThreadWithUnread();

    final entry = _entryOf(room);

    expect(entry.unreadCount, 1);
    expect(entry.mentionCount, 1);
  });

  test('a room whose only unread is a muted thread is not in the Unread '
      'folder', () {
    _mutedThreadWithUnread();

    expect(_unreadFolderIds(), isEmpty);
  });

  test('a folded space holding a room whose only unread is a muted thread '
      'counts 0', () {
    _mutedThreadWithUnread();

    final row = _foldedSpaceRow();

    expect(row.unreadCount, 0);
    expect(row.mentionCount, 0);
  });
}

/// P2: the explicit choice wins over taking part.
void _followChoiceTests() {
  test('the replies of a thread the user took part in, then unfollowed, '
      'are not counted', () {
    final room = _room();
    _followThread();
    _threadCounters((unread: 4, mentions: 0));
    _choose(ThreadPref.unfollow);

    final entry = _entryOf(room);

    expect(entry.unreadCount, 0);
    expect(entry.isUnread, isFalse);
  });

  test('the replies of a thread the user followed without replying are '
      'counted', () async {
    final room = _room();
    await _notFollowedThread((unread: 2, mentions: 0));
    _choose(ThreadPref.follow);

    final entry = _entryOf(room);

    expect(entry.unreadCount, 2);
    expect(entry.isUnread, isTrue);
  });

  test('a room whose only unread is a thread the user followed without '
      'replying is in the Unread folder', () async {
    await _notFollowedThread((unread: 1, mentions: 0));
    _choose(ThreadPref.follow);

    expect(_unreadFolderIds(), [_roomId]);
  });
}
