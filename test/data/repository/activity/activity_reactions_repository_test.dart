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

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 3: the
/// reactions of the others to the messages of the user, from the history
/// the client holds (here: what the sync brought), newest first, 50 at most;
/// a reaction taken back is dropped (web D58). The messages reacted to here
/// are all in what the sync brought: nothing is asked of the server. A live
/// reaction to a message the app has not seen asks the server for it
/// (activity_reactions_older_message_test.dart, bounded in
/// activity_reactions_server_lookup_test.dart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(RecordingHomeserver());
    // The room open on screen: all its states (the members) held.
    await _account.receiveRoomState(const []);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(_account),
    );
    addTearDown(container.dispose);
    _repository = container
        .listen(activityReactionsRepositoryProvider, (_, _) {})
        .read();
  });

  tearDown(() async {
    await _subscription?.cancel();
    _subscription = null;
    _seen.clear();
  });

  test('a reaction of someone else to a message of the user: who, the emoji, '
      'the message, the room and when', () async {
    await _syncTeam([
      _message(r'$mine', threadOwner, 'the deck is ready', _at(9)),
      _reaction(r'$r1', _frank, r'$mine', '🎉', _at(9, 5)),
    ]);

    final reaction = (await _shown()).single;

    expect(reaction.kind, ActivityKind.reaction);
    expect(reaction.authorName, 'Frank Moore');
    expect(reaction.emoji, '🎉');
    expect(reaction.quote, 'the deck is ready');
    expect(reaction.eventId, r'$mine');
    expect(reaction.roomId, teamRoomId);
    expect(reaction.roomName, 'Team');
    expect(reaction.time, _sameInstant(_at(9, 5)));
    expect(reaction.threadRootId, isNull);
  });

  test('the reactions of the user are not listed', () async {
    await _syncTeam([
      _message(r'$mine', threadOwner, 'the deck is ready', _at(9)),
      _reaction(r'$r1', threadOwner, r'$mine', '👍', _at(9, 5)),
      _reaction(r'$r2', _frank, r'$mine', '🎉', _at(9, 6)),
    ]);

    expect((await _shown()).map((r) => r.emoji), ['🎉']);
  });

  test('a reaction to the message of someone else is not listed', () async {
    await _syncTeam([
      _message(r'$theirs', _frank, 'lunch?', _at(9)),
      _message(r'$mine', threadOwner, 'the deck is ready', _at(9, 1)),
      _reaction(r'$r1', _grace, r'$theirs', '👍', _at(9, 5)),
      _reaction(r'$r2', _grace, r'$mine', '🎉', _at(9, 6)),
    ]);

    expect((await _shown()).map((r) => r.eventId), [r'$mine']);
  });

  test('a reaction to a thread reply of the user carries its thread', () async {
    await _syncTeam([
      _threadReply(
        r'$my_reply',
        threadOwner,
        'I can take it',
        _at(9),
        rootId: lunchThread.rootEventId,
      ),
      _reaction(r'$r1', _frank, r'$my_reply', '👍', _at(9, 5)),
    ]);

    final reaction = (await _shown()).single;

    expect(reaction.eventId, r'$my_reply');
    expect(reaction.threadRootId, lunchThread.rootEventId);
  });

  test('a reaction arriving by the sync shows without a refresh', () async {
    await _syncTeam([
      _message(r'$mine', threadOwner, 'the deck is ready', _at(9)),
    ]);
    expect(await _shown(), isEmpty);

    await _syncTeam([_reaction(r'$r1', _frank, r'$mine', '🎉', _at(10))]);

    expect((await _shown()).single.emoji, '🎉');
  });

  test('a reaction taken back leaves the list', () async {
    await _syncTeam([
      _message(r'$mine', threadOwner, 'the deck is ready', _at(9)),
      _reaction(r'$r1', _frank, r'$mine', '🎉', _at(9, 5)),
    ]);
    expect(await _shown(), hasLength(1));

    await _syncTeam([
      {
        'type': EventTypes.Redaction,
        'event_id': r'$undo',
        'sender': _frank,
        'redacts': r'$r1',
        'origin_server_ts': _at(9, 6).millisecondsSinceEpoch,
        'content': {'redacts': r'$r1'},
      },
    ]);

    expect(await _shown(), isEmpty);
  });

  test('the newest first, 50 at most', () async {
    await _syncTeam([
      _message(r'$mine', threadOwner, 'the deck is ready', _at(8)),
      for (var i = 0; i < 55; i++)
        _reaction('\$r$i', _frank, r'$mine', 'e$i', _at(9, i)),
    ]);

    final reactions = await _shown();

    expect(reactions, hasLength(50));
    expect(reactions.first.emoji, 'e54');
    expect(reactions.last.emoji, 'e5');
    final times = reactions.map((r) => r.time).toList();
    expect(times, orderedEquals([...times]..sort((a, b) => b.compareTo(a))));
  });
}

late ThreadAccount _account;
late ActivityReactionsRepository _repository;

const _frank = '@frank:example.org';
const _grace = '@grace:example.org';

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
  ..._message(eventId, sender, body, at),
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
