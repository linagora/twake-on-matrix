import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

import '../../../providers/fake_active_account.dart';
import '../../datasource_impl/thread/thread_account.dart';

/// THR-M-12, slice 1, found on the real app (QA 2026-11-12): in « All », a
/// reply in a followed thread showed twice, as the last message of its
/// unread room (« bob sent a message ») and as the last reply of the
/// thread. The row of an unread room shows the newest message of the main
/// timeline, never a thread reply; a room unread only for a followed thread
/// shows its last main message, or none. The reply shows once, as a reply.
///
/// The device keeps the timeline of each sync, as the app's database does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(RecordingHomeserver(), storedTimeline: const []);
    await _account.receiveRoomState(const []);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(_account),
    );
    addTearDown(container.dispose);
    _repository = container
        .listen(activityRepositoryProvider, (_, _) {})
        .read();
    _account.server.answer(
      ServerRoute.get('rooms/$teamRoomId/event/${lunchThread.rootEventId}'),
      _lunchRoot,
    );
    await _account.receiveThreadPrefs([
      prefEntry(lunchThread, WirePref.follow),
    ]);
  });

  tearDown(() async {
    await _subscription?.cancel();
    _subscription = null;
    _seen.clear();
  });

  test('a room with an unread message then a reply in a followed thread shows '
      'the message, not the reply; the reply shows once, as a reply', () async {
    await _syncTeam(
      timeline: [
        _message(r'$m1', _alice, 'see you there', _at(9)),
        _reply(r'$late', _bob, 'Running late', _at(10, 30)),
      ],
      notificationCount: 1,
      threadNotifications: 1,
    );

    final items = await _shown();
    final showingReply = items.where((item) => item.quote == 'Running late');
    expect(showingReply.map((item) => item.kind), [ActivityKind.reply]);
    final room = _unreadRoom(items);

    expect(room.quote, 'see you there');
    expect(room.authorName, 'Alice Durand');
    expect(room.time, _sameInstant(_at(9)));
  });

  test('a reply arriving in a later sync does not replace the last message '
      'of the unread room', () async {
    await _syncTeam(
      timeline: [_message(r'$m1', _alice, 'see you there', _at(9))],
      notificationCount: 1,
    );
    expect(_unreadRoom(await _shown()).quote, 'see you there');

    await _syncTeam(
      timeline: [_reply(r'$late', _bob, 'Running late', _at(10, 30))],
      notificationCount: 1,
      threadNotifications: 1,
    );

    final items = await _shown();
    final showingReply = items.where((item) => item.quote == 'Running late');
    expect(showingReply.map((item) => item.kind), [ActivityKind.reply]);
    expect(_unreadRoom(items).quote, 'see you there');
    expect(_unreadRoom(items).authorName, 'Alice Durand');
  });

  test('a room unread only for a reply in a followed thread shows its last '
      'main message, or none, never the reply', () async {
    await _syncTeam(timeline: [_message(r'$m1', _alice, 'old news', _at(8))]);
    await _syncTeam(
      timeline: [_reply(r'$late', _bob, 'Running late', _at(10, 30))],
      threadNotifications: 2,
    );

    final items = await _shown();
    final showingReply = items.where((item) => item.quote == 'Running late');
    expect(showingReply.map((item) => item.kind), [ActivityKind.reply]);
    final room = _unreadRoom(items);

    expect(room.unreadCount, 2);
    expect(room.quote, anyOf(isNull, 'old news'));
  });

  test('a room whose only message is a reply in a followed thread is unread '
      'with no last message', () async {
    await _syncTeam(
      timeline: [_reply(r'$late', _bob, 'Running late', _at(10, 30))],
      threadNotifications: 1,
    );

    final items = await _shown();
    final showingReply = items.where((item) => item.quote == 'Running late');
    expect(showingReply.map((item) => item.kind), [ActivityKind.reply]);
    final room = _unreadRoom(items);

    expect(room.unreadCount, 1);
    expect(room.quote, isNull);
    expect(room.authorName, isNot('Bob Martin'));
  });
}

late ThreadAccount _account;
late ActivityRepository _repository;

const _bob = '@bob:example.org';
const _alice = '@alice:example.org';

DateTime _at(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 11, 12, hour, minute);

final List<List<ActivityItem>> _seen = [];
StreamSubscription<List<ActivityItem>>? _subscription;

Future<List<ActivityItem>> _shown() async {
  _subscription ??= _repository.watchActivity().listen(_seen.add);
  await _settle(_seen);
  expect(_seen, isNotEmpty, reason: 'the list emits at once');
  return _seen.last;
}

ActivityItem _unreadRoom(List<ActivityItem> items) =>
    items.singleWhere((item) => item.kind == ActivityKind.unreadRoom);

/// Lets the follow lookups, the root fetches and the streams run: returns
/// once [seen] got nothing new for 1.2 s, longer than the 1 s rate limit (8 s at most).
Future<void> _settle(List<Object?> seen) async {
  final deadline = DateTime.now().add(const Duration(seconds: 8));
  var count = -1;
  var quiet = 0;
  while (quiet < 60 && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    quiet = seen.length == count ? quiet + 1 : 0;
    count = seen.length;
  }
}

Matcher _sameInstant(DateTime expected) => predicate<DateTime>(
  (actual) => actual.isAtSameMomentAs(expected),
  'the instant $expected',
);

Map<String, Object?> _member(String userId, String name) => {
  'type': EventTypes.RoomMember,
  'state_key': userId,
  'sender': userId,
  'event_id': '\$member$userId',
  'origin_server_ts': _at(7).millisecondsSinceEpoch,
  'content': {'membership': 'join', 'displayname': name},
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

/// A reply in the lunch thread.
Map<String, Object?> _reply(
  String eventId,
  String sender,
  String body,
  DateTime at,
) => {
  ..._message(eventId, sender, body, at),
  'content': {
    'msgtype': 'm.text',
    'body': body,
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': lunchThread.rootEventId,
      'is_falling_back': true,
      'm.in_reply_to': {'event_id': lunchThread.rootEventId},
    },
  },
};

/// The root of the lunch thread as the server gives it, its last reply
/// older than the replies of the tests.
final Map<String, Object?> _lunchRoot = {
  ..._message(lunchThread.rootEventId, _bob, 'Lunch on Friday?', _at(7)),
  'room_id': teamRoomId,
  'unsigned': {
    'm.relations': {
      'm.thread': {
        'count': 1,
        'current_user_participated': false,
        'latest_event': {
          ..._reply(r'$first', _alice, 'Pizza?', _at(7, 30)),
          'room_id': teamRoomId,
        },
      },
    },
  },
};

/// A sync brings the team room (« Team », Bob, Alice and the user) with
/// [timeline], its unread count and that of the lunch thread.
Future<void> _syncTeam({
  List<Map<String, Object?>> timeline = const [],
  int notificationCount = 0,
  int threadNotifications = 0,
}) => _account.receiveSync({
  'rooms': {
    'join': {
      teamRoomId: {
        'state': {
          'events': [
            {
              'type': EventTypes.RoomName,
              'state_key': '',
              'sender': threadOwner,
              'event_id': r'$name',
              'origin_server_ts': _at(7).millisecondsSinceEpoch,
              'content': {'name': 'Team'},
            },
            _member(threadOwner, 'Me Myself'),
            _member(_bob, 'Bob Martin'),
            _member(_alice, 'Alice Durand'),
          ],
        },
        'timeline': {'events': timeline, 'limited': false},
        'unread_notifications': {
          'notification_count': notificationCount,
          'highlight_count': 0,
        },
        'unread_thread_notifications': {
          if (threadNotifications > 0)
            lunchThread.rootEventId: {
              'notification_count': threadNotifications,
              'highlight_count': 0,
            },
        },
      },
    },
  },
});
