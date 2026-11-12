import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_reactions_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_reactions_repository.dart';

import 'activity_sync_events.dart';
import '../../../providers/fake_active_account.dart';
import '../../datasource_impl/thread/thread_account.dart';

/// THR-M-12, slice 3: a live reaction to a message the app has not seen
/// asks the server for that message (activity_reactions_older_message_test).
/// The asking is bounded: one request per message ever, found, missing or
/// someone else's; none for a reaction read in a history page; 20 at once,
/// the budget coming back over time (activity_reactions_store_budget_test);
/// a logout starts afresh. A message found to be someone else's is
/// remembered: its next reactions read neither the device nor the server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(RecordingHomeserver());
    await _account.receiveRoomState(const []);
    _container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(_account),
    );
    addTearDown(_container.dispose);
    _repository = _container
        .listen(activityReactionsRepositoryProvider, (_, _) {})
        .read();
  });

  tearDown(() async {
    await _subscription?.cancel();
    _subscription = null;
    _seen.clear();
  });

  test('many live reactions to the same older message ask the server once, '
      'and all are listed', () async {
    _account.server.answer(
      _lookupOf(r'$old'),
      _oldMessage((id: r'$old', sender: threadOwner)),
    );

    await _syncTeam([
      reactionEvent((
        id: r'$r1',
        sender: _frank,
        target: r'$old',
        key: '❤️',
        at: 10.utc,
      )),
      reactionEvent((
        id: r'$r2',
        sender: _grace,
        target: r'$old',
        key: '👍',
        at: (10, 1).utc,
      )),
      reactionEvent((
        id: r'$r3',
        sender: _frank,
        target: r'$old',
        key: '🎉',
        at: (10, 2).utc,
      )),
    ]);
    await _syncTeam([
      reactionEvent((
        id: r'$r4',
        sender: _grace,
        target: r'$old',
        key: '🚀',
        at: (10, 3).utc,
      )),
    ]);

    expect((await _shown()).map((r) => r.emoji), ['🚀', '🎉', '👍', '❤️']);
    expect(_account.server.callsTo(_lookupOf(r'$old')), hasLength(1));
  });

  test('a reaction read in a history page asks nothing of the server and is '
      'not listed', () async {
    _account.server.answer(
      _lookupOf(r'$old'),
      _oldMessage((id: r'$old', sender: threadOwner)),
    );
    await _syncTeam(const []);

    await _loadHistory([
      reactionEvent((
        id: r'$r1',
        sender: _frank,
        target: r'$old',
        key: '❤️',
        at: 6.utc,
      )),
    ]);

    expect(await _shown(), isEmpty);
    expect(_account.server.callsTo(_lookupOf(r'$old')), isEmpty);
  });

  test('a message the server does not find is not asked again', () async {
    _account.server.fail(_lookupOf(r'$gone'), ServerError.notFound);

    await _syncTeam([
      reactionEvent((
        id: r'$r1',
        sender: _frank,
        target: r'$gone',
        key: '❤️',
        at: 10.utc,
      )),
    ]);
    await _syncTeam([
      reactionEvent((
        id: r'$r2',
        sender: _grace,
        target: r'$gone',
        key: '👍',
        at: (10, 1).utc,
      )),
    ]);
    await _shown();

    expect(_account.server.callsTo(_lookupOf(r'$gone')), hasLength(1));
  });

  test('a message found to be someone else\'s is remembered: its next '
      'reactions read neither the device nor the server', () async {
    _account.server.answer(
      _lookupOf(r'$theirs'),
      _oldMessage((id: r'$theirs', sender: _grace)),
    );

    await _syncTeam([
      reactionEvent((
        id: r'$r1',
        sender: _frank,
        target: r'$theirs',
        key: '❤️',
        at: 10.utc,
      )),
    ]);
    await _shown();
    expect(_account.server.callsTo(_lookupOf(r'$theirs')), hasLength(1));
    int deviceReads() =>
        _account.deviceEventReads.where((id) => id == r'$theirs').length;
    final readsBefore = deviceReads();

    await _syncTeam([
      reactionEvent((
        id: r'$r2',
        sender: _frank,
        target: r'$theirs',
        key: '👍',
        at: (10, 1).utc,
      )),
    ]);

    expect(await _shown(), isEmpty);
    expect(_account.server.callsTo(_lookupOf(r'$theirs')), hasLength(1));
    expect(deviceReads(), readsBefore);
  });

  test(
    'after 20 messages asked at once, the next ones are not asked now',
    () async {
      _account.server.fail(_anyLookup, ServerError.notFound);

      await _syncTeam([
        for (var i = 0; i < 20; i++)
          reactionEvent((
            id: '\$r$i',
            sender: _frank,
            target: '\$old$i',
            key: '❤️',
            at: (10, i).utc,
          )),
      ]);
      await _shown();
      expect(_account.server.callsTo(_anyLookup), hasLength(20));

      await _syncTeam([
        reactionEvent((
          id: r'$r20',
          sender: _frank,
          target: r'$old20',
          key: '❤️',
          at: 11.utc,
        )),
        reactionEvent((
          id: r'$r21',
          sender: _grace,
          target: r'$old21',
          key: '👍',
          at: (11, 1).utc,
        )),
      ]);
      await _shown();

      expect(_account.server.callsTo(_anyLookup), hasLength(20));
    },
  );

  test('after a logout, the messages are asked again', () async {
    _account.server.fail(_anyLookup, ServerError.notFound);
    await _syncTeam([
      for (var i = 0; i < 20; i++)
        reactionEvent((
          id: '\$r$i',
          sender: _frank,
          target: '\$old$i',
          key: '❤️',
          at: (10, i).utc,
        )),
    ]);
    await _shown();
    expect(_account.server.callsTo(_anyLookup), hasLength(20));

    // The next sync after the login brings nothing old again.
    _account.server.answer(const ServerRoute.get('sync'), {'next_batch': 's3'});
    await _account.logOutThenLogIn(threadOwner);
    await _account.receiveRoomState(const []);
    _account.server.answer(
      _lookupOf(r'$after'),
      _oldMessage((id: r'$after', sender: threadOwner)),
    );
    await _syncTeam([
      reactionEvent((
        id: r'$r99',
        sender: _frank,
        target: r'$after',
        key: '❤️',
        at: 12.utc,
      )),
    ]);
    await _shown();

    expect(_account.server.callsTo(_lookupOf(r'$after')), hasLength(1));
  });
}

late ThreadAccount _account;
late ProviderContainer _container;
late ActivityReactionsRepository _repository;

const _frank = '@frank:example.org';
const _grace = '@grace:example.org';

/// Every request for one event of the team room.
const _anyLookup = ServerRoute.get('rooms/$teamRoomId/event/');

ServerRoute _lookupOf(String eventId) =>
    ServerRoute.get('rooms/$teamRoomId/event/$eventId');

final List<List<ActivityItem>> _seen = [];
StreamSubscription<List<ActivityItem>>? _subscription;

Future<List<ActivityItem>> _shown() async {
  _subscription ??= _repository.watchReactions().listen(_seen.add);
  await _settle(_seen);
  expect(_seen, isNotEmpty, reason: 'the list emits at once');
  return _seen.last;
}

Future<void> _syncTeam(List<Map<String, Object?>> timeline) =>
    _account.receiveSync({
      'rooms': {
        'join': {
          teamRoomId: {
            'state': {
              'events': [
                teamNameEvent,
                memberEvent((id: threadOwner, name: 'Me Myself')),
                memberEvent((id: _frank, name: 'Frank Moore')),
                memberEvent((id: _grace, name: 'Grace Hall')),
              ],
            },
            'timeline': {'events': timeline, 'limited': false},
          },
        },
      },
    });

/// The user scrolls up the team room: a history page brings [events],
/// oldest first.
Future<void> _loadHistory(List<Map<String, Object?>> events) async {
  _account.server.answer(const ServerRoute.get('rooms/$teamRoomId/messages'), {
    'chunk': [
      for (final event in events.reversed) {...event, 'room_id': teamRoomId},
    ],
    'start': 'p1',
    'end': 'p0',
  });
  final room = _account.getRoomById(teamRoomId)!..prev_batch = 'p1';
  await room.requestHistory();
}

/// Lets the lookups and the streams run: returns once neither [seen] nor
/// the requests to the server grew for 200 ms (5 s at most).
Future<void> _settle(List<Object?> seen) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  var count = -1;
  var quiet = 0;
  while (quiet < 10 && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final now = seen.length + _account.server.calls.length;
    quiet = now == count ? quiet + 1 : 0;
    count = now;
  }
}

/// A message from last week: its event id and who sent it.
typedef _Old = ({String id, String sender});

/// [old] as the server gives it.
Map<String, Object?> _oldMessage(_Old old) => {
  ...messageEvent((
    id: old.id,
    sender: old.sender,
    body: 'the plan from last week',
    at: DateTime.utc(2026, 11, 5, 9),
  )),
  'room_id': teamRoomId,
};
