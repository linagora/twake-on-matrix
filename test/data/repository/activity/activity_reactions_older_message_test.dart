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

/// THR-M-12, slice 3, found on the real app (QA 2026-11-12): a live
/// reaction of someone else to an older message of the user, one the app
/// had not seen in this session, never showed (❤️ on an old message), while
/// one to a recent message did (🎉). The reaction is listed once its
/// message is found: on the device first, then on the server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> open({List<Map<String, Object?>>? storedTimeline}) async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(
      RecordingHomeserver(),
      storedTimeline: storedTimeline,
    );
    await _account.receiveRoomState(const []);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverrides(_account),
    );
    addTearDown(container.dispose);
    _repository = container
        .listen(activityReactionsRepositoryProvider, (_, _) {})
        .read();
  }

  tearDown(() async {
    await _subscription?.cancel();
    _subscription = null;
    _seen.clear();
  });

  test('a reaction to an older message of the user, read from the server, '
      'is listed with that message', () async {
    await open();
    _account.server.answer(_oldMessageRoute, _oldMessage(threadOwner));

    await _syncTeam([_reaction(r'$heart', _frank, r'$old', '❤️', _at(10))]);

    final reactions = await _shown();
    expect(reactions, hasLength(1), reason: 'the ❤️ is listed');
    final reaction = reactions.single;
    expect(reaction.emoji, '❤️');
    expect(reaction.authorName, 'Frank Moore');
    expect(reaction.quote, 'the plan from last week');
    expect(reaction.eventId, r'$old');
    expect(reaction.time, _sameInstant(_at(10)));
  });

  test('a reaction to an older message the device holds is listed without '
      'asking the server', () async {
    await open(storedTimeline: [_oldMessage(threadOwner)]);

    await _syncTeam([_reaction(r'$heart', _frank, r'$old', '❤️', _at(10))]);

    expect((await _shown()).single.quote, 'the plan from last week');
    expect(_account.server.callsTo(_oldMessageRoute), isEmpty);
  });

  test('a reaction to an older message of someone else, read from the '
      'server, is not listed', () async {
    await open();
    _account.server.answer(_oldMessageRoute, _oldMessage(_grace));

    await _syncTeam([_reaction(r'$heart', _frank, r'$old', '❤️', _at(10))]);

    expect(await _shown(), isEmpty);
    expect(
      _account.server.callsTo(_oldMessageRoute),
      isNotEmpty,
      reason: 'the message was looked for',
    );
  });

  test('a reaction to a message the server does not find is not listed, and '
      'the next reactions still are', () async {
    await open();
    _account.server.fail(_oldMessageRoute, ServerError.notFound);

    await _syncTeam([
      _reaction(r'$heart', _frank, r'$old', '❤️', _at(10)),
      _message(r'$mine', threadOwner, 'the deck is ready', _at(10, 1)),
      _reaction(r'$party', _frank, r'$mine', '🎉', _at(10, 2)),
    ]);

    expect((await _shown()).map((r) => r.emoji), ['🎉']);
    expect(_account.server.callsTo(_oldMessageRoute), isNotEmpty);
  });

  test('a reaction to a message the server cannot give now is not listed, '
      'and the next reactions still are', () async {
    await open();
    _account.server.fail(_oldMessageRoute);

    await _syncTeam([
      _reaction(r'$heart', _frank, r'$old', '❤️', _at(10)),
      _message(r'$mine', threadOwner, 'the deck is ready', _at(10, 1)),
      _reaction(r'$party', _frank, r'$mine', '🎉', _at(10, 2)),
    ]);

    expect((await _shown()).map((r) => r.emoji), ['🎉']);
    expect(_account.server.callsTo(_oldMessageRoute), isNotEmpty);
  });
}

late ThreadAccount _account;
late ActivityReactionsRepository _repository;

const _frank = '@frank:example.org';
const _grace = '@grace:example.org';

const _oldMessageRoute = ServerRoute.get(r'rooms/!team:example.org/event/$old');

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

/// A message of [sender] from last week, as the server (or the device)
/// gives it.
Map<String, Object?> _oldMessage(String sender) => {
  ..._message(
    r'$old',
    sender,
    'the plan from last week',
    DateTime.utc(2026, 11, 5, 9),
  ),
  'room_id': teamRoomId,
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

/// Lets the lookups and the streams run: returns once [seen] got nothing
/// new for 200 ms (5 s at most).
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

Matcher _sameInstant(DateTime expected) => predicate<DateTime>(
  (actual) => actual.isAtSameMomentAs(expected),
  'the instant $expected',
);
