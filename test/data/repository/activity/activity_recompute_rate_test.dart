import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

import 'activity_sync_events.dart';
import '../../../providers/fake_active_account.dart';
import '../../datasource_impl/thread/thread_account.dart';

/// THR-M-12, slice 1 (review 2026-11-12): the Activity is read again at
/// each sync, each change of the thread counters and each root read. A
/// burst of them is read at most about once a second, as the room list
/// does (a 1 s rate limit), the last state always shown in the end.
///
/// The bound: one list at once, then at most one per second the burst
/// lasted, plus the last one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThreadAccount account;
  late ActivityRepository repository;
  final seen = <List<ActivityItem>>[];
  StreamSubscription<List<ActivityItem>>? subscription;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    account = ThreadAccount(RecordingHomeserver());
    await account.receiveRoomState(const []);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(account),
    );
    addTearDown(container.dispose);
    repository = container.listen(activityRepositoryProvider, (_, _) {}).read();
  });

  tearDown(() async {
    await subscription?.cancel();
    subscription = null;
    seen.clear();
  });

  /// Waits until no list came for 1.5 s (longer than the rate limit), 10 s
  /// at most.
  Future<void> settle() async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    var count = -1;
    var quiet = 0;
    while (quiet < 15 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      quiet = seen.length == count ? quiet + 1 : 0;
      count = seen.length;
    }
  }

  Matcher atMostOnePerSecondOf(Duration burst) =>
      lessThanOrEqualTo(2 + burst.inSeconds + 1);

  test('ten syncs in a burst are not read ten times, and the last one '
      'shows', () async {
    await _syncTeam(account, (messages: 0));
    subscription = repository.watchActivity().listen(seen.add);
    await settle();
    final before = seen.length;

    final burst = Stopwatch()..start();
    for (var i = 1; i <= 10; i++) {
      await _syncTeam(account, (messages: i));
    }
    burst.stop();
    await settle();

    expect(seen.length - before, atMostOnePerSecondOf(burst.elapsed));
    final room = seen.last.singleWhere(
      (item) => item.kind == ActivityKind.unreadRoom,
    );
    expect(room.quote, 'message 10');
    expect(room.unreadCount, 10);
  });

  test('opening with ten followed threads does not show ten lists, one per '
      'root read, and shows the ten in the end', () async {
    final threads = [
      for (var i = 0; i < 10; i++) ThreadRef(teamRoomId, '\$root$i'),
    ];
    ServerRoute rootOf(ThreadRef thread) =>
        ServerRoute.get('rooms/$teamRoomId/event/${thread.rootEventId}');
    for (final thread in threads) {
      account.server
        ..answer(rootOf(thread), _root(thread))
        // A slow network: the roots come one after another.
        ..hold(rootOf(thread));
    }
    await _syncTeam(account, (messages: 0));
    await account.receiveThreadPrefs([
      for (final thread in threads) prefEntry(thread, WirePref.follow),
    ]);

    final opening = Stopwatch()..start();
    subscription = repository.watchActivity().listen(seen.add);
    for (final thread in threads) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      account.server.release(rootOf(thread));
    }
    await settle();
    opening.stop();

    // The opening lasts until the last list plus the quiet wait.
    final reading = opening.elapsed - const Duration(milliseconds: 1500);
    expect(seen.length, atMostOnePerSecondOf(reading));
    expect(
      seen.last.where((item) => item.kind == ActivityKind.reply),
      hasLength(10),
    );
  });
}

const _bob = '@bob:example.org';

/// [said] as the server sends it, with its room.
Map<String, Object?> _bobSays(Said said) => {
  ...messageEvent(said),
  'room_id': teamRoomId,
};

/// The root of [thread] with one reply of Bob.
Map<String, Object?> _root(ThreadRef thread) {
  final rootId = thread.rootEventId;
  return {
    ..._bobSays((id: rootId, sender: _bob, body: 'topic $rootId', at: 9.utc)),
    'unsigned': {
      'm.relations': {
        'm.thread': {
          'count': 1,
          'current_user_participated': false,
          'latest_event': {
            ..._bobSays((
              id: '${rootId}_reply',
              sender: _bob,
              body: 'reply in $rootId',
              at: (9, 1).utc,
            )),
            'content': {
              'msgtype': 'm.text',
              'body': 'reply in $rootId',
              'm.relates_to': {'rel_type': 'm.thread', 'event_id': rootId},
            },
          },
        },
      },
    },
  };
}

/// How many messages of Bob the room holds, all unread.
typedef _Unread = ({int messages});

/// A sync brings the last of [unread] messages of Bob (none for 0), unread
/// with the ones before.
Future<void> _syncTeam(ThreadAccount account, _Unread unread) {
  final index = unread.messages;
  return account.receiveSync({
    'rooms': {
      'join': {
        teamRoomId: {
          'state': {
            'events': [memberEvent((id: _bob, name: 'Bob'))],
          },
          'timeline': {
            'events': [
              if (index > 0)
                _bobSays((
                  id: '\$m$index',
                  sender: _bob,
                  body: 'message $index',
                  at: (9, 10 + index).utc,
                )),
            ],
            'limited': false,
          },
          'unread_notifications': {
            'notification_count': index,
            'highlight_count': 0,
          },
        },
      },
    },
  });
}
