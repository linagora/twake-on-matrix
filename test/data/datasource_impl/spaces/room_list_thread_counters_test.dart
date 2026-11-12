// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/space_child.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/data/datasource_impl/spaces/room_list_entry_mapper.dart';
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

MockRoom _room(
  String id, {
  int notifications = 0,
  int highlights = 0,
  bool isSpace = false,
  List<String> children = const [],
}) {
  final room = MockRoom();
  when(room.id).thenReturn(id);
  when(room.client).thenReturn(_client);
  when(room.membership).thenReturn(Membership.join);
  when(room.isSpace).thenReturn(isSpace);
  when(room.tags).thenReturn({});
  when(room.spaceParents).thenReturn([]);
  when(room.spaceChildren).thenReturn([
    for (final child in children)
      SpaceChild.fromState(
        StrippedStateEvent(
          type: EventTypes.SpaceChild,
          senderId: '@a:example.com',
          stateKey: child,
          content: {
            'via': ['example.com'],
          },
        ),
      ),
  ]);
  when(room.notificationCount).thenReturn(notifications);
  when(room.highlightCount).thenReturn(highlights);
  return room;
}

/// The user replied in the thread (P1: participation is following).
void _followThread(String roomId) =>
    _store.markFollowed(ThreadRef(roomId, _rootId));

/// What a sync says of the thread of [roomId].
void _threadCounters(String roomId, {required int replies, int mentions = 0}) =>
    _store.apply(
      SyncThreadUpdate(
        counts: {
          roomId: {
            _rootId: (notificationCount: replies, highlightCount: mentions),
          },
        },
        leftRoomIds: const [],
      ),
    );

/// The thread got replies; the server says the user does not take part.
Future<void> _notFollowedThread(
  String roomId, {
  required int replies,
  int mentions = 0,
}) async {
  _threadCounters(roomId, replies: replies, mentions: mentions);
  await pumpEventQueue();
  expect(
    await _store.followOnceKnown(ThreadRef(roomId, _rootId)),
    isFalse,
    reason: 'setup: the lookup answered "not participated"',
  );
}

RoomListEntry _entryOf(Room room) =>
    roomListEntriesOf([room], directChats: const {}).single;

void _entryCountTests() {
  test('a room whose only unread is a followed thread shows its replies', () {
    final room = _room(_roomId);
    _followThread(_roomId);
    _threadCounters(_roomId, replies: 2);

    final entry = _entryOf(room);

    expect(entry.unreadCount, 2);
    expect(entry.isUnread, isTrue);
  });

  test('main timeline and followed thread unreads add up', () {
    final room = _room(_roomId, notifications: 1);
    _followThread(_roomId);
    _threadCounters(_roomId, replies: 2);

    expect(_entryOf(room).unreadCount, 3);
  });

  test('a mention in a thread is a mention of the room', () async {
    final room = _room(_roomId);
    await _notFollowedThread(_roomId, replies: 1, mentions: 1);

    final entry = _entryOf(room);

    expect(entry.mentionCount, 1);
    expect(entry.unreadCount, 1);
  });

  test('mentions of the room and of its threads add up', () {
    final room = _room(_roomId, notifications: 1, highlights: 1);
    _followThread(_roomId);
    _threadCounters(_roomId, replies: 2, mentions: 1);

    expect(_entryOf(room).mentionCount, 2);
  });

  // Guard: green before the fix too; it must stay green after it.
  test(
    'replies of a thread the user does not follow are not counted',
    () async {
      final room = _room(_roomId);
      await _notFollowedThread(_roomId, replies: 4);

      final entry = _entryOf(room);

      expect(entry.unreadCount, 0);
      expect(entry.mentionCount, 0);
      expect(entry.isUnread, isFalse);
    },
  );
}

void _unreadFolderTests() {
  List<RoomListEntry> unreadFolder(List<Room> rooms) => visibleEntries(
    roomListEntriesOf(rooms, directChats: const {}),
    view: const RoomListFilter.builtin(BuiltinFolder.unread),
  );

  test('keeps a room whose only unread is a followed thread', () {
    final room = _room(_roomId);
    _followThread(_roomId);
    _threadCounters(_roomId, replies: 1);

    expect(unreadFolder([room]).map((e) => e.id), [_roomId]);
  });

  test('keeps a room whose only unread is a thread mention', () async {
    final room = _room(_roomId);
    await _notFollowedThread(_roomId, replies: 1, mentions: 1);

    expect(unreadFolder([room]).map((e) => e.id), [_roomId]);
  });
}

void _spaceCountTests() {
  RoomListSpaceRow spaceRow(List<Room> rooms) => buildRoomListRows(
    roomListEntriesOf(rooms, directChats: const {}),
    foldedSpaceIds: {_spaceId},
  ).whereType<RoomListSpaceRow>().single;

  List<Room> spaceWithRoom() => [
    _room(_spaceId, isSpace: true, children: [_roomId]),
    _room(_roomId),
  ];

  test('counts a thread mention of a room it holds', () async {
    final rooms = spaceWithRoom();
    await _notFollowedThread(_roomId, replies: 1, mentions: 1);

    expect(spaceRow(rooms).mentionCount, 1);
  });

  test('counts the followed thread replies of a room it holds', () {
    final rooms = spaceWithRoom();
    _followThread(_roomId);
    _threadCounters(_roomId, replies: 3);

    expect(spaceRow(rooms).unreadCount, 3);
  });
}

/// The flag fully gates this level: off, the room list shows the server
/// room counters only, as before threads.
void _threadsOffTests() {
  setUp(() => AppConfig.threadsEnabled = false);

  // Guard: green before the fix too; it must stay green after it.
  test('the room list shows the server room counters only', () {
    final room = _room(_roomId, notifications: 1);
    _followThread(_roomId);
    _threadCounters(_roomId, replies: 2, mentions: 1);

    final entry = _entryOf(room);

    expect(entry.unreadCount, 1);
    expect(entry.mentionCount, 0);
  });
}
