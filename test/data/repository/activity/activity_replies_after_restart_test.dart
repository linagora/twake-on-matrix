import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

import 'activity_sync_events.dart';
import '../../../providers/fake_active_account.dart';
import '../../datasource_impl/thread/thread_account.dart';

/// THR-M-12, slice 1 (review 2026-11-12): after a restart, the app knows no
/// reply of the session; the root of a followed thread comes from the
/// device, where its thread aggregate may be old or missing. A followed
/// thread stays in « Replies » with its true last reply, as the server
/// knows it; a root that could not be read is read again at a later change.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The app starts again on a device holding [stored], talking to
  /// [server]; the lunch thread is followed by choice.
  Future<void> restart(
    RecordingHomeserver server, {
    List<Map<String, Object?>> stored = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(server, storedTimeline: stored);
    await _account.receiveRoomState(const []);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(_account),
    );
    addTearDown(container.dispose);
    _repository = container
        .listen(activityRepositoryProvider, (_, _) {})
        .read();
    await _syncTeam();
    await _account.receiveThreadPrefs([
      prefEntry(lunchThread, WirePref.follow),
    ]);
  }

  /// A server that gives the root of the lunch thread with [latest] as its
  /// last reply.
  RecordingHomeserver serverGivingRoot(Map<String, Object?> latest) =>
      RecordingHomeserver()..answer(_rootRoute, _root(latest: latest));

  tearDown(() async {
    await _subscription?.cancel();
    _subscription = null;
    _seen.clear();
  });

  test('a followed thread whose stored root holds an old aggregate shows the '
      'last reply the server knows', () async {
    await restart(
      serverGivingRoot(_shipIt),
      stored: [_root(latest: _oldReply)],
    );

    final thread = _threads(await _shown()).single;

    expect(thread.quote, 'Ship it');
    expect(thread.authorName, 'Alice Durand');
    expect(thread.time, sameInstant(10.utc));
  });

  test(
    'a followed thread whose stored root holds an aggregate without its '
    'last reply is still listed, with the last reply the server knows',
    () async {
      await restart(serverGivingRoot(_shipIt), stored: [_root()]);

      final threads = _threads(await _shown());

      expect(threads, hasLength(1), reason: 'the thread is listed');
      expect(threads.single.quote, 'Ship it');
    },
  );

  test('a root that could not be read is read again at the next sync, and '
      'the thread then shows', () async {
    await restart(RecordingHomeserver()..fail(_rootRoute));
    expect(_threads(await _shown()), isEmpty);
    expect(_account.server.callsTo(_rootRoute), isNotEmpty);

    // The server is back.
    _account.server
      ..recover(_rootRoute)
      ..answer(_rootRoute, _root(latest: _shipIt));
    await _syncTeam();

    final threads = _threads(await _shown());
    expect(threads, hasLength(1), reason: 'the root was read again');
    expect(threads.single.quote, 'Ship it');
  });
}

late ThreadAccount _account;
late ActivityRepository _repository;

const _bob = '@bob:example.org';
const _alice = '@alice:example.org';

final _rootRoute = ServerRoute.get(
  'rooms/$teamRoomId/event/${lunchThread.rootEventId}',
);

final List<List<ActivityItem>> _seen = [];
StreamSubscription<List<ActivityItem>>? _subscription;

Future<List<ActivityItem>> _shown() async {
  _subscription ??= _repository.watchActivity().listen(_seen.add);
  await settle(_seen);
  expect(_seen, isNotEmpty, reason: 'the list emits at once');
  return _seen.last;
}

List<ActivityItem> _threads(List<ActivityItem> items) =>
    items.where((item) => item.kind == ActivityKind.reply).toList();

final _oldReply = {
  ...threadReplyEvent((
    id: r'$old_reply',
    sender: _alice,
    body: 'Pizza?',
    at: (7, 30).utc,
  ), lunchThread),
  'room_id': teamRoomId,
};
final _shipIt = {
  ...threadReplyEvent((
    id: r'$ship_it',
    sender: _alice,
    body: 'Ship it',
    at: 10.utc,
  ), lunchThread),
  'room_id': teamRoomId,
};

/// The root of the lunch thread with its thread aggregate: [latest] is its
/// last reply; none: the aggregate holds no last reply.
Map<String, Object?> _root({Map<String, Object?>? latest}) => {
  ...{
    ...messageEvent((
      id: lunchThread.rootEventId,
      sender: _bob,
      body: 'Lunch on Friday?',
      at: 7.utc,
    )),
    'room_id': teamRoomId,
  },
  'unsigned': {
    'm.relations': {
      'm.thread': {
        'count': 2,
        'current_user_participated': false,
        'latest_event': ?latest,
      },
    },
  },
};

/// A sync brings the team room (« Team », Bob, Alice and the user), nothing
/// unread.
Future<void> _syncTeam() => _account.receiveSync({
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
              'origin_server_ts': 6.utc.millisecondsSinceEpoch,
              'content': {'name': 'Team'},
            },
            memberEvent((id: threadOwner, name: 'Me Myself')),
            memberEvent((id: _bob, name: 'Bob Martin')),
            memberEvent((id: _alice, name: 'Alice Durand')),
          ],
        },
      },
    },
  },
});
