import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

import '../../../providers/fake_active_account.dart';
import '../../../utils/thread_unread/thread_fakes.dart';
import '../../datasource_impl/thread/thread_account.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 1: the
/// unread rooms and the followed threads come from the sync data already in
/// memory, and follow every sync without a refresh. « Unread »: one item per
/// unread room, its unread count, its last message (web D57). « Replies »:
/// the threads followed (an explicit choice wins over taking part; a muted
/// or unfollowed thread is not there), the author and text of their last
/// reply, the room, the start of the root, resolved, unread count (D185).
/// The count of the tab and title: the unread mentions, as the badge of the
/// rooms counts them (rooms and threads, a muted thread counting none).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(RecordingHomeserver());
    // The room open on screen: all its states (the members) held.
    await _account.receiveRoomState(const []);
    _container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(_account),
    );
    addTearDown(_container.dispose);
    final repository = _container.listen(activityRepositoryProvider, (_, _) {});
    _repository = repository.read();
    _answerRoot(_lunchRoot());
    _answerRoot(_releaseRoot());
  });

  tearDown(() async {
    await _itemsSubscription?.cancel();
    _itemsSubscription = null;
    await _countSubscription?.cancel();
    _countSubscription = null;
    _items.clear();
    _counts.clear();
  });

  group('« Unread »', _unreadRoomTests);
  group('« Replies »', _followedThreadTests);
  group('the unread mentions count', _mentionCountTests);
  group('« Mark as read »', _markReadTests);
}

late ThreadAccount _account;
late ProviderContainer _container;
late ActivityRepository _repository;

const _bob = '@bob:example.org';
const _alice = '@alice:example.org';
const _otherRoomId = '!other:example.org';

DateTime _at(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 11, 12, hour, minute);

final List<List<ActivityItem>> _items = [];
final List<int> _counts = [];
StreamSubscription<List<ActivityItem>>? _itemsSubscription;
StreamSubscription<int>? _countSubscription;

/// What the list shows now, once whatever the sync started has settled.
Future<List<ActivityItem>> _shown() async {
  _itemsSubscription ??= _repository.watchActivity().listen(_items.add);
  await _settle(_items);
  expect(_items, isNotEmpty, reason: 'the list emits at once');
  return _items.last;
}

Future<int> _countShown() async {
  _countSubscription ??= _repository.watchUnreadMentionCount().listen(
    _counts.add,
  );
  await _settle(_counts);
  expect(_counts, isNotEmpty, reason: 'the count emits at once');
  return _counts.last;
}

/// Lets the follow lookups, the root fetches and the streams run: returns
/// once [seen] got nothing new for 200 ms (5 s at most).
Future<void> _settle(List<Object?> seen) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  var count = -1;
  var quiet = 0;
  while (quiet < 10 && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    quiet = seen.length == count ? quiet + 1 : 0;
    count = seen.length;
  }
}

/// The same instant, whatever the time zone the SDK gives the date in.
Matcher _sameInstant(DateTime expected) => predicate<DateTime>(
  (actual) => actual.isAtSameMomentAs(expected),
  'the instant $expected',
);

List<ActivityItem> _unreadRooms(List<ActivityItem> items) =>
    items.where((item) => item.kind == ActivityKind.unreadRoom).toList();

List<ActivityItem> _threads(List<ActivityItem> items) =>
    items.where((item) => item.kind == ActivityKind.reply).toList();

Map<String, Object?> _member(String userId, String name) => {
  'type': EventTypes.RoomMember,
  'state_key': userId,
  'sender': userId,
  'event_id': '\$member$userId',
  'origin_server_ts': _at(8).millisecondsSinceEpoch,
  'content': {'membership': 'join', 'displayname': name},
};

Map<String, Object?> _roomName(String name) => {
  'type': EventTypes.RoomName,
  'state_key': '',
  'sender': threadOwner,
  'event_id': '\$name$name',
  'origin_server_ts': _at(8).millisecondsSinceEpoch,
  'content': {'name': name},
};

Map<String, Object?> _message(
  String eventId,
  String sender,
  String body,
  DateTime at,
) => {
  'type': EventTypes.Message,
  'event_id': eventId,
  'sender': sender,
  'origin_server_ts': at.millisecondsSinceEpoch,
  'content': {'msgtype': 'm.text', 'body': body},
};

Map<String, Object?> _threadReply(
  String eventId,
  String sender,
  String body,
  DateTime at, {
  required String rootId,
}) => {
  'type': EventTypes.Message,
  'event_id': eventId,
  'sender': sender,
  'origin_server_ts': at.millisecondsSinceEpoch,
  'content': {
    'msgtype': 'm.text',
    'body': body,
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': rootId,
      'is_falling_back': true,
      'm.in_reply_to': {'event_id': rootId},
    },
  },
};

/// The root of a thread as the server gives it, with the aggregate of the
/// thread: [latest] is its last reply.
Map<String, Object?> _root(
  String rootId,
  String body, {
  required Map<String, Object?> latest,
  required int count,
  required bool participated,
}) => {
  ..._message(rootId, _bob, body, _at(7)),
  'room_id': teamRoomId,
  'unsigned': {
    'm.relations': {
      'm.thread': {
        'count': count,
        'current_user_participated': participated,
        'latest_event': {...latest, 'room_id': teamRoomId},
      },
    },
  },
};

Map<String, Object?> _lunchRoot({bool participated = true}) => _root(
  lunchThread.rootEventId,
  'Lunch on Friday? Pick a place',
  latest: _threadReply(
    r'$lunch_last',
    _alice,
    'Ship it',
    _at(10),
    rootId: lunchThread.rootEventId,
  ),
  count: 3,
  participated: participated,
);

Map<String, Object?> _releaseRoot() => _root(
  releaseThread.rootEventId,
  'Release notes draft',
  latest: _threadReply(
    r'$release_old',
    _alice,
    'old reply',
    _at(7, 30),
    rootId: releaseThread.rootEventId,
  ),
  count: 1,
  participated: false,
);

/// The server answers the root of [root] (and what the user took part in).
void _answerRoot(Map<String, Object?> root) => _account.server.answer(
  ServerRoute.get('rooms/$teamRoomId/event/${root['event_id']}'),
  root,
);

/// A sync brings the team room (« Team », Bob, Alice and the user as
/// members) with [timeline], its counters and those of its threads.
Future<void> _syncTeam({
  List<Map<String, Object?>> timeline = const [],
  int notificationCount = 0,
  int highlightCount = 0,
  Map<String, ({int notifications, int highlights})> threads = const {},
  List<Map<String, Object?>> state = const [],
}) => _account.receiveSync({
  'rooms': {
    'join': {
      teamRoomId: {
        'state': {
          'events': [
            _roomName('Team'),
            _member(threadOwner, 'Me Myself'),
            _member(_bob, 'Bob Martin'),
            _member(_alice, 'Alice Durand'),
            ...state,
          ],
        },
        'timeline': {'events': timeline, 'limited': false},
        'unread_notifications': {
          'notification_count': notificationCount,
          'highlight_count': highlightCount,
        },
        'unread_thread_notifications': {
          for (final thread in threads.entries)
            thread.key: {
              'notification_count': thread.value.notifications,
              'highlight_count': thread.value.highlights,
            },
        },
      },
    },
  },
});

Future<void> _choose(ThreadRef thread, WirePref pref) =>
    _chooseAll({thread: pref});

/// The choices of the user, as one `app.twake.chat.thread_prefs` content.
Future<void> _chooseAll(Map<ThreadRef, WirePref> choices) =>
    _account.receiveThreadPrefs([
      for (final choice in choices.entries) prefEntry(choice.key, choice.value),
    ]);

void _unreadRoomTests() {
  test('an unread room is one item: its name, its unread count, its last '
      'message and who sent it', () async {
    await _syncTeam(
      timeline: [
        _message(r'$m1', _bob, 'first', _at(9)),
        _message(r'$m2', _alice, 'second', _at(9, 10)),
        _message(r'$m3', _bob, 'see you there', _at(9, 20)),
      ],
      notificationCount: 3,
    );

    final rooms = _unreadRooms(await _shown());

    expect(rooms, hasLength(1));
    final room = rooms.single;
    expect(room.roomId, teamRoomId);
    expect(room.roomName, 'Team');
    expect(room.unreadCount, 3);
    expect(room.quote, 'see you there');
    expect(room.authorName, 'Bob Martin');
    expect(room.time, _sameInstant(_at(9, 20)));
  });

  test('a read room is not in « Unread »', () async {
    await _syncTeam(timeline: [_message(r'$m1', _bob, 'old', _at(9))]);

    expect(_unreadRooms(await _shown()), isEmpty);
  });

  test('a room whose only unread replies are in a followed thread is unread, '
      'with their count', () async {
    await _choose(lunchThread, WirePref.follow);
    await _syncTeam(
      threads: {lunchThread.rootEventId: (notifications: 2, highlights: 0)},
    );

    final room = _unreadRooms(await _shown()).single;

    expect(room.roomId, teamRoomId);
    expect(room.unreadCount, 2);
  });

  test('a new message in a read room makes it join « Unread » without a '
      'refresh', () async {
    await _syncTeam(timeline: [_message(r'$m1', _bob, 'old', _at(9))]);
    expect(_unreadRooms(await _shown()), isEmpty);

    await _syncTeam(
      timeline: [_message(r'$m2', _bob, 'are you there?', _at(11))],
      notificationCount: 1,
    );

    final room = _unreadRooms(await _shown()).single;
    expect(room.quote, 'are you there?');
    expect(room.unreadCount, 1);
  });

  test('a room read on another device leaves « Unread » without a '
      'refresh', () async {
    await _syncTeam(
      timeline: [_message(r'$m1', _bob, 'see you there', _at(9))],
      notificationCount: 1,
    );
    expect(_unreadRooms(await _shown()), hasLength(1));

    await _syncTeam();

    expect(_unreadRooms(await _shown()), isEmpty);
  });
}

void _followedThreadTests() {
  test('a thread the user took part in shows the author and text of its last '
      'reply, its room, the start of its root and its unread count', () async {
    await _syncTeam(
      threads: {lunchThread.rootEventId: (notifications: 2, highlights: 0)},
    );

    final thread = _threads(await _shown()).single;

    expect(thread.roomId, teamRoomId);
    expect(thread.roomName, 'Team');
    expect(thread.threadRootId, lunchThread.rootEventId);
    expect(thread.threadTitle, startsWith('Lunch on Friday'));
    expect(thread.authorName, 'Alice Durand');
    expect(thread.quote, 'Ship it');
    expect(thread.unreadCount, 2);
    expect(thread.time, _sameInstant(_at(10)));
  });

  test('a thread followed by choice, all read, is in « Replies » with '
      'nothing unread', () async {
    _answerRoot(_lunchRoot(participated: false));
    await _syncTeam();
    await _choose(lunchThread, WirePref.follow);

    final thread = _threads(await _shown()).single;

    expect(thread.threadRootId, lunchThread.rootEventId);
    expect(thread.quote, 'Ship it');
    expect(thread.unreadCount, 0);
  });

  /// Beside each thread left out, the release thread is followed by choice:
  /// the list is not empty for want of a source.
  test('a thread the user wrote in, then unfollowed, is not in '
      '« Replies »', () async {
    await _chooseAll({
      lunchThread: WirePref.unfollow,
      releaseThread: WirePref.follow,
    });
    await _syncTeam(
      threads: {lunchThread.rootEventId: (notifications: 2, highlights: 0)},
    );

    expect(_threads(await _shown()).map((t) => t.threadRootId), [
      releaseThread.rootEventId,
    ]);
  });

  test('a muted thread is not in « Replies »', () async {
    await _chooseAll({
      lunchThread: WirePref.mute,
      releaseThread: WirePref.follow,
    });
    await _syncTeam(
      threads: {lunchThread.rootEventId: (notifications: 2, highlights: 0)},
    );

    expect(_threads(await _shown()).map((t) => t.threadRootId), [
      releaseThread.rootEventId,
    ]);
  });

  test('a thread the user does not follow is not in « Replies »', () async {
    _answerRoot(_lunchRoot(participated: false));
    await _chooseAll({releaseThread: WirePref.follow});
    await _syncTeam(
      threads: {lunchThread.rootEventId: (notifications: 2, highlights: 0)},
    );

    expect(_threads(await _shown()).map((t) => t.threadRootId), [
      releaseThread.rootEventId,
    ]);
  });

  test('muting a followed thread on the web takes it out of « Replies » '
      'without a refresh', () async {
    await _syncTeam();
    await _choose(lunchThread, WirePref.follow);
    expect(_threads(await _shown()), hasLength(1));

    await _choose(lunchThread, WirePref.mute);

    expect(_threads(await _shown()), isEmpty);
  });

  test('a resolved thread is marked resolved, a reopened one is not, without '
      'a refresh', () async {
    await _syncTeam(state: [_resolved(lunchThread, true)]);
    await _choose(lunchThread, WirePref.follow);
    expect(_threads(await _shown()).single.isResolved, isTrue);

    await _syncTeam(state: [_resolved(lunchThread, false)]);

    expect(_threads(await _shown()).single.isResolved, isFalse);
  });

  test('a reply the user sends from another device makes the thread followed '
      'and shows as its last reply, without a refresh', () async {
    await _syncTeam();
    expect(_threads(await _shown()), isEmpty);

    await _syncTeam(
      timeline: [
        _threadReply(
          r'$mine',
          threadOwner,
          'On it',
          _at(11),
          rootId: releaseThread.rootEventId,
        ),
      ],
    );

    final thread = _threads(await _shown()).single;
    expect(thread.threadRootId, releaseThread.rootEventId);
    expect(thread.quote, 'On it');
    expect(thread.authorName, 'Me Myself');
    expect(thread.time, _sameInstant(_at(11)));
  });

  test('a new reply in a followed thread becomes its last reply without a '
      'refresh', () async {
    await _syncTeam();
    await _choose(lunchThread, WirePref.follow);
    expect(_threads(await _shown()).single.quote, 'Ship it');

    await _syncTeam(
      timeline: [
        _threadReply(
          r'$late',
          _bob,
          'Running late',
          _at(12),
          rootId: lunchThread.rootEventId,
        ),
      ],
      threads: {lunchThread.rootEventId: (notifications: 1, highlights: 0)},
    );

    final thread = _threads(await _shown()).single;
    expect(thread.quote, 'Running late');
    expect(thread.authorName, 'Bob Martin');
    expect(thread.unreadCount, 1);
  });
}

Map<String, Object?> _resolved(ThreadRef thread, bool resolved) => {
  'type': 'app.twake.chat.thread_resolved',
  'state_key': thread.rootEventId,
  'sender': threadOwner,
  'event_id': '\$resolved${thread.rootEventId}$resolved',
  'origin_server_ts': _at(8, resolved ? 1 : 2).millisecondsSinceEpoch,
  'content': {'resolved': resolved},
};

void _mentionCountTests() {
  test('the count is the unread mentions of the rooms and of their threads, '
      'followed or not', () async {
    _answerRoot(_lunchRoot(participated: false));
    await _syncTeam(
      notificationCount: 1,
      highlightCount: 1,
      threads: {lunchThread.rootEventId: (notifications: 2, highlights: 2)},
    );

    expect(await _countShown(), 3);
  });

  test('the mentions of a muted thread do not count', () async {
    await _choose(lunchThread, WirePref.mute);
    await _syncTeam(
      notificationCount: 1,
      highlightCount: 1,
      threads: {lunchThread.rootEventId: (notifications: 2, highlights: 2)},
    );

    expect(await _countShown(), 1);
  });

  test('with no unread mention, the count is 0', () async {
    await _syncTeam(notificationCount: 4);

    expect(await _countShown(), 0);
  });

  test('the count follows the sync without a refresh', () async {
    await _syncTeam(notificationCount: 1, highlightCount: 1);
    expect(await _countShown(), 1);

    await _syncTeam();

    expect(await _countShown(), 0);
  });
}

/// « Mark as read » reads the main timeline and the threads of the room
/// (THR-M-06, maintainer decision of 11/11: one unthreaded receipt on the
/// newest event, which covers every thread; see
/// test/utils/thread_unread/mark_room_and_all_threads_read_test.dart).
void _markReadTests() {
  late RecordingThreadClient client;
  late ProviderContainer container;

  setUp(() {
    client = RecordingThreadClient();
    when(client.clientName).thenReturn('account-a');
    when(client.userID).thenReturn(threadOwner);
    when(client.receiptsPublicByDefault).thenReturn(true);
    when(
      client.roomPreviewLastEvents,
    ).thenReturn({EventTypes.Message, EventTypes.Encrypted});
    when(client.onSync).thenReturn(CachedStreamController());
    when(client.onTimelineEvent).thenReturn(CachedStreamController());
    when(client.onHistoryEvent).thenReturn(CachedStreamController());
    when(client.onRoomState).thenReturn(CachedStreamController());
    when(client.onAccountData).thenReturn(CachedStreamController());
    final room = Room(id: _otherRoomId, client: client);
    when(client.rooms).thenReturn([room]);
    when(client.getRoomById(_otherRoomId)).thenReturn(room);
    final reply = Event(
      type: EventTypes.Message,
      content: {
        'msgtype': 'm.text',
        'body': 'newest, in a thread',
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': r'$root',
          'is_falling_back': true,
        },
      },
      eventId: r'$newest',
      senderId: _bob,
      originServerTs: _at(10),
      room: room,
    );
    final main = Event(
      type: EventTypes.Message,
      content: const {'msgtype': 'm.text', 'body': 'main'},
      eventId: r'$main',
      senderId: _bob,
      originServerTs: _at(9),
      room: room,
    );
    when(client.database).thenReturn(StoredEvents([reply, main]));
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(client),
    );
    addTearDown(container.dispose);
  });

  test(
    'reads the room up to its newest event, thread replies included',
    () async {
      final repository = container
          .listen(activityRepositoryProvider, (_, _) {})
          .read();

      await repository.markRoomRead(_otherRoomId);

      expect(client.receipts.map((r) => r.eventId), [r'$newest']);
      expect(client.receipts.single.threadId, isNull);
      expect(client.fullyRead, [r'$main']);
    },
  );
}
