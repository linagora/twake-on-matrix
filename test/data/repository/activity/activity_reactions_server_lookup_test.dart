import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_reactions_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_reactions_repository.dart';

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
    _account.server.answer(_lookupOf(r'$old'), _myOldMessage(r'$old'));

    await _syncTeam([
      _reaction(r'$r1', _frank, r'$old', '❤️', _at(10)),
      _reaction(r'$r2', _grace, r'$old', '👍', _at(10, 1)),
      _reaction(r'$r3', _frank, r'$old', '🎉', _at(10, 2)),
    ]);
    await _syncTeam([_reaction(r'$r4', _grace, r'$old', '🚀', _at(10, 3))]);

    expect((await _shown()).map((r) => r.emoji), ['🚀', '🎉', '👍', '❤️']);
    expect(_account.server.callsTo(_lookupOf(r'$old')), hasLength(1));
  });

  test('a reaction read in a history page asks nothing of the server and is '
      'not listed', () async {
    _account.server.answer(_lookupOf(r'$old'), _myOldMessage(r'$old'));
    await _syncTeam(const []);

    await _loadHistory([_reaction(r'$r1', _frank, r'$old', '❤️', _at(6))]);

    expect(await _shown(), isEmpty);
    expect(_account.server.callsTo(_lookupOf(r'$old')), isEmpty);
  });

  test('a message the server does not find is not asked again', () async {
    _account.server.fail(_lookupOf(r'$gone'), ServerError.notFound);

    await _syncTeam([_reaction(r'$r1', _frank, r'$gone', '❤️', _at(10))]);
    await _syncTeam([_reaction(r'$r2', _grace, r'$gone', '👍', _at(10, 1))]);
    await _shown();

    expect(_account.server.callsTo(_lookupOf(r'$gone')), hasLength(1));
  });

  test('a message found to be someone else\'s is remembered: its next '
      'reactions read neither the device nor the server', () async {
    _account.server.answer(
      _lookupOf(r'$theirs'),
      _oldMessageOf(r'$theirs', _grace),
    );

    await _syncTeam([_reaction(r'$r1', _frank, r'$theirs', '❤️', _at(10))]);
    await _shown();
    expect(_account.server.callsTo(_lookupOf(r'$theirs')), hasLength(1));
    int deviceReads() =>
        _account.deviceEventReads.where((id) => id == r'$theirs').length;
    final readsBefore = deviceReads();

    await _syncTeam([_reaction(r'$r2', _frank, r'$theirs', '👍', _at(10, 1))]);

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
          _reaction('\$r$i', _frank, '\$old$i', '❤️', _at(10, i)),
      ]);
      await _shown();
      expect(_account.server.callsTo(_anyLookup), hasLength(20));

      await _syncTeam([
        _reaction(r'$r20', _frank, r'$old20', '❤️', _at(11)),
        _reaction(r'$r21', _grace, r'$old21', '👍', _at(11, 1)),
      ]);
      await _shown();

      expect(_account.server.callsTo(_anyLookup), hasLength(20));
    },
  );

  test('after a logout, the messages are asked again', () async {
    _account.server.fail(_anyLookup, ServerError.notFound);
    await _syncTeam([
      for (var i = 0; i < 20; i++)
        _reaction('\$r$i', _frank, '\$old$i', '❤️', _at(10, i)),
    ]);
    await _shown();
    expect(_account.server.callsTo(_anyLookup), hasLength(20));

    // The next sync after the login brings nothing old again.
    _account.server.answer(const ServerRoute.get('sync'), {'next_batch': 's3'});
    await _account.logOutThenLogIn(threadOwner);
    await _account.receiveRoomState(const []);
    _account.server.answer(_lookupOf(r'$after'), _myOldMessage(r'$after'));
    await _syncTeam([_reaction(r'$r99', _frank, r'$after', '❤️', _at(12))]);
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

DateTime _at(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 11, 12, hour, minute);

final List<List<ActivityItem>> _seen = [];
StreamSubscription<List<ActivityItem>>? _subscription;

Future<List<ActivityItem>> _shown() async {
  _subscription ??= _repository.watchReactions().listen(_seen.add);
  await _settle(_seen);
  expect(_seen, isNotEmpty, reason: 'the list emits at once');
  return _seen.last;
}

/// A message of the user from last week, as the server gives it.
Map<String, Object?> _myOldMessage(String eventId) =>
    _oldMessageOf(eventId, threadOwner);

/// A message of [sender] from last week, as the server gives it.
Map<String, Object?> _oldMessageOf(String eventId, String sender) => {
  'type': EventTypes.Message,
  'event_id': eventId,
  'sender': sender,
  'room_id': teamRoomId,
  'origin_server_ts': DateTime.utc(2026, 11, 5, 9).millisecondsSinceEpoch,
  'content': {'msgtype': 'm.text', 'body': 'the plan from last week'},
};

Future<void> _syncTeam(List<Map<String, Object?>> timeline) =>
    _account.receiveSync({
      'rooms': {
        'join': {
          teamRoomId: {
            'state': {
              'events': [
                _state(EventTypes.RoomName, '', {'name': 'Team'}),
                _member(threadOwner, 'Me Myself'),
                _member(_frank, 'Frank Moore'),
                _member(_grace, 'Grace Hall'),
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

Map<String, Object?> _state(
  String type,
  String stateKey,
  Map<String, Object?> content,
) => {
  'type': type,
  'state_key': stateKey,
  'sender': threadOwner,
  'event_id': '\$$type$stateKey',
  'origin_server_ts': _at(7).millisecondsSinceEpoch,
  'content': content,
};

Map<String, Object?> _member(String userId, String name) => _state(
  EventTypes.RoomMember,
  userId,
  {'membership': 'join', 'displayname': name},
);

Map<String, Object?> _reaction(
  String eventId,
  String sender,
  String target,
  String key,
  DateTime at,
) => {
  'type': EventTypes.Reaction,
  'event_id': eventId,
  'sender': sender,
  'origin_server_ts': at.millisecondsSinceEpoch,
  'content': {
    'm.relates_to': {
      'rel_type': RelationshipTypes.reaction,
      'event_id': target,
      'key': key,
    },
  },
};

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
