import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

import 'activity_sync_events.dart';
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
    await _TeamSync(
      timeline: [
        messageEvent((
          id: r'$m1',
          sender: _alice,
          body: 'see you there',
          at: 9.utc,
        )),
        threadReplyEvent((
          id: r'$late',
          sender: _bob,
          body: 'Running late',
          at: (10, 30).utc,
        ), lunchThread),
      ],
      notificationCount: 1,
      threadNotifications: 1,
    ).send();

    final items = await _shown();
    final showingReply = items.where((item) => item.quote == 'Running late');
    expect(showingReply.map((item) => item.kind), [ActivityKind.reply]);
    final room = _unreadRoom(items);

    expect(room.quote, 'see you there');
    expect(room.authorName, 'Alice Durand');
    expect(room.time, sameInstant(9.utc));
  });

  test('a reply arriving in a later sync does not replace the last message '
      'of the unread room', () async {
    await _TeamSync(
      timeline: [
        messageEvent((
          id: r'$m1',
          sender: _alice,
          body: 'see you there',
          at: 9.utc,
        )),
      ],
      notificationCount: 1,
    ).send();
    expect(_unreadRoom(await _shown()).quote, 'see you there');

    await _TeamSync(
      timeline: [
        threadReplyEvent((
          id: r'$late',
          sender: _bob,
          body: 'Running late',
          at: (10, 30).utc,
        ), lunchThread),
      ],
      notificationCount: 1,
      threadNotifications: 1,
    ).send();

    final items = await _shown();
    final showingReply = items.where((item) => item.quote == 'Running late');
    expect(showingReply.map((item) => item.kind), [ActivityKind.reply]);
    expect(_unreadRoom(items).quote, 'see you there');
    expect(_unreadRoom(items).authorName, 'Alice Durand');
  });

  test('a room unread only for a reply in a followed thread shows its last '
      'main message, or none, never the reply', () async {
    await _TeamSync(
      timeline: [
        messageEvent((id: r'$m1', sender: _alice, body: 'old news', at: 8.utc)),
      ],
    ).send();
    await _TeamSync(
      timeline: [
        threadReplyEvent((
          id: r'$late',
          sender: _bob,
          body: 'Running late',
          at: (10, 30).utc,
        ), lunchThread),
      ],
      threadNotifications: 2,
    ).send();

    final items = await _shown();
    final showingReply = items.where((item) => item.quote == 'Running late');
    expect(showingReply.map((item) => item.kind), [ActivityKind.reply]);
    final room = _unreadRoom(items);

    expect(room.unreadCount, 2);
    expect(room.quote, anyOf(isNull, 'old news'));
  });

  test('a room whose only message is a reply in a followed thread is unread '
      'with no last message', () async {
    await _TeamSync(
      timeline: [
        threadReplyEvent((
          id: r'$late',
          sender: _bob,
          body: 'Running late',
          at: (10, 30).utc,
        ), lunchThread),
      ],
      threadNotifications: 1,
    ).send();

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

final List<List<ActivityItem>> _seen = [];
StreamSubscription<List<ActivityItem>>? _subscription;

Future<List<ActivityItem>> _shown() async {
  _subscription ??= _repository.watchActivity().listen(_seen.add);
  await settle(_seen);
  expect(_seen, isNotEmpty, reason: 'the list emits at once');
  return _seen.last;
}

ActivityItem _unreadRoom(List<ActivityItem> items) =>
    items.singleWhere((item) => item.kind == ActivityKind.unreadRoom);

/// The root of the lunch thread as the server gives it, its last reply
/// older than the replies of the tests.
final Map<String, Object?> _lunchRoot = {
  ...messageEvent((
    id: lunchThread.rootEventId,
    sender: _bob,
    body: 'Lunch on Friday?',
    at: 7.utc,
  )),
  'room_id': teamRoomId,
  'unsigned': {
    'm.relations': {
      'm.thread': {
        'count': 1,
        'current_user_participated': false,
        'latest_event': {
          ...threadReplyEvent((
            id: r'$first',
            sender: _alice,
            body: 'Pizza?',
            at: (7, 30).utc,
          ), lunchThread),
          'room_id': teamRoomId,
        },
      },
    },
  },
};

/// A sync brings the team room (« Team », Bob, Alice and the user) with
/// [timeline], its unread count and that of the lunch thread.
class _TeamSync {
  const _TeamSync({
    this.timeline = const [],
    this.notificationCount = 0,
    this.threadNotifications = 0,
  });

  final List<Map<String, Object?>> timeline;
  final int notificationCount;
  final int threadNotifications;

  Future<void> send() => _account.receiveSync({
    'rooms': {
      'join': {
        teamRoomId: {
          'state': {
            'events': [
              teamNameEvent,
              memberEvent((id: threadOwner, name: 'Me Myself')),
              memberEvent((id: _bob, name: 'Bob Martin')),
              memberEvent((id: _alice, name: 'Alice Durand')),
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
}
