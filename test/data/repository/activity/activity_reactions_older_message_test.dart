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
    _account.server.answer(_oldMessageRoute, _myOldMessage);

    await _syncTeam([
      reactionEvent((
        id: r'$heart',
        sender: _frank,
        target: r'$old',
        key: '❤️',
        at: 10.utc,
      )),
    ]);

    final reactions = await _shown();
    expect(reactions, hasLength(1), reason: 'the ❤️ is listed');
    final reaction = reactions.single;
    expect(reaction.emoji, '❤️');
    expect(reaction.authorName, 'Frank Moore');
    expect(reaction.quote, 'the plan from last week');
    expect(reaction.eventId, r'$old');
    expect(reaction.time, sameInstant(10.utc));
  });

  test('a reaction to an older message the device holds is listed without '
      'asking the server', () async {
    await open(storedTimeline: [_myOldMessage]);

    await _syncTeam([
      reactionEvent((
        id: r'$heart',
        sender: _frank,
        target: r'$old',
        key: '❤️',
        at: 10.utc,
      )),
    ]);

    expect((await _shown()).single.quote, 'the plan from last week');
    expect(_account.server.callsTo(_oldMessageRoute), isEmpty);
  });

  test('a reaction to an older message of someone else, read from the '
      'server, is not listed', () async {
    await open();
    _account.server.answer(_oldMessageRoute, _gracesOldMessage);

    await _syncTeam([
      reactionEvent((
        id: r'$heart',
        sender: _frank,
        target: r'$old',
        key: '❤️',
        at: 10.utc,
      )),
    ]);

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
      reactionEvent((
        id: r'$heart',
        sender: _frank,
        target: r'$old',
        key: '❤️',
        at: 10.utc,
      )),
      messageEvent((
        id: r'$mine',
        sender: threadOwner,
        body: 'the deck is ready',
        at: (10, 1).utc,
      )),
      reactionEvent((
        id: r'$party',
        sender: _frank,
        target: r'$mine',
        key: '🎉',
        at: (10, 2).utc,
      )),
    ]);

    expect((await _shown()).map((r) => r.emoji), ['🎉']);
    expect(_account.server.callsTo(_oldMessageRoute), isNotEmpty);
  });

  test('a reaction to a message the server cannot give now is not listed, '
      'and the next reactions still are', () async {
    await open();
    _account.server.fail(_oldMessageRoute);

    await _syncTeam([
      reactionEvent((
        id: r'$heart',
        sender: _frank,
        target: r'$old',
        key: '❤️',
        at: 10.utc,
      )),
      messageEvent((
        id: r'$mine',
        sender: threadOwner,
        body: 'the deck is ready',
        at: (10, 1).utc,
      )),
      reactionEvent((
        id: r'$party',
        sender: _frank,
        target: r'$mine',
        key: '🎉',
        at: (10, 2).utc,
      )),
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

final List<List<ActivityItem>> _seen = [];
StreamSubscription<List<ActivityItem>>? _subscription;

Future<List<ActivityItem>> _shown() async {
  _subscription ??= _repository.watchReactions().listen(_seen.add);
  await settle(_seen);
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

/// A message of the user from last week, as the server (or the device)
/// gives it.
final Map<String, Object?> _myOldMessage = {
  ...messageEvent((
    id: r'$old',
    sender: threadOwner,
    body: 'the plan from last week',
    at: DateTime.utc(2026, 11, 5, 9),
  )),
  'room_id': teamRoomId,
};

/// The same message, written by Grace.
final Map<String, Object?> _gracesOldMessage = {
  ..._myOldMessage,
  'sender': _grace,
};
