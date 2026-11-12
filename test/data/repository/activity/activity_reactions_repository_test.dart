import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/repository/activity/activity_reactions_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_reactions_repository.dart';

import 'activity_sync_events.dart';
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
      messageEvent((
        id: r'$mine',
        sender: threadOwner,
        body: 'the deck is ready',
        at: 9.utc,
      )),
      reactionEvent((
        id: r'$r1',
        sender: _frank,
        target: r'$mine',
        key: '🎉',
        at: (9, 5).utc,
      )),
    ]);

    final reaction = (await _shown()).single;

    expect(reaction.kind, ActivityKind.reaction);
    expect(reaction.authorName, 'Frank Moore');
    expect(reaction.emoji, '🎉');
    expect(reaction.quote, 'the deck is ready');
    expect(reaction.eventId, r'$mine');
    expect(reaction.roomId, teamRoomId);
    expect(reaction.roomName, 'Team');
    expect(reaction.time, sameInstant((9, 5).utc));
    expect(reaction.threadRootId, isNull);
  });

  test('the reactions of the user are not listed', () async {
    await _syncTeam([
      messageEvent((
        id: r'$mine',
        sender: threadOwner,
        body: 'the deck is ready',
        at: 9.utc,
      )),
      reactionEvent((
        id: r'$r1',
        sender: threadOwner,
        target: r'$mine',
        key: '👍',
        at: (9, 5).utc,
      )),
      reactionEvent((
        id: r'$r2',
        sender: _frank,
        target: r'$mine',
        key: '🎉',
        at: (9, 6).utc,
      )),
    ]);

    expect((await _shown()).map((r) => r.emoji), ['🎉']);
  });

  test('a reaction to the message of someone else is not listed', () async {
    await _syncTeam([
      messageEvent((id: r'$theirs', sender: _frank, body: 'lunch?', at: 9.utc)),
      messageEvent((
        id: r'$mine',
        sender: threadOwner,
        body: 'the deck is ready',
        at: (9, 1).utc,
      )),
      reactionEvent((
        id: r'$r1',
        sender: _grace,
        target: r'$theirs',
        key: '👍',
        at: (9, 5).utc,
      )),
      reactionEvent((
        id: r'$r2',
        sender: _grace,
        target: r'$mine',
        key: '🎉',
        at: (9, 6).utc,
      )),
    ]);

    expect((await _shown()).map((r) => r.eventId), [r'$mine']);
  });

  test('a reaction to a thread reply of the user carries its thread', () async {
    await _syncTeam([
      threadReplyEvent((
        id: r'$my_reply',
        sender: threadOwner,
        body: 'I can take it',
        at: 9.utc,
      ), lunchThread),
      reactionEvent((
        id: r'$r1',
        sender: _frank,
        target: r'$my_reply',
        key: '👍',
        at: (9, 5).utc,
      )),
    ]);

    final reaction = (await _shown()).single;

    expect(reaction.eventId, r'$my_reply');
    expect(reaction.threadRootId, lunchThread.rootEventId);
  });

  test('a reaction arriving by the sync shows without a refresh', () async {
    await _syncTeam([
      messageEvent((
        id: r'$mine',
        sender: threadOwner,
        body: 'the deck is ready',
        at: 9.utc,
      )),
    ]);
    expect(await _shown(), isEmpty);

    await _syncTeam([
      reactionEvent((
        id: r'$r1',
        sender: _frank,
        target: r'$mine',
        key: '🎉',
        at: 10.utc,
      )),
    ]);

    expect((await _shown()).single.emoji, '🎉');
  });

  test('a reaction taken back leaves the list', () async {
    await _syncTeam([
      messageEvent((
        id: r'$mine',
        sender: threadOwner,
        body: 'the deck is ready',
        at: 9.utc,
      )),
      reactionEvent((
        id: r'$r1',
        sender: _frank,
        target: r'$mine',
        key: '🎉',
        at: (9, 5).utc,
      )),
    ]);
    expect(await _shown(), hasLength(1));

    await _syncTeam([
      {
        'type': EventTypes.Redaction,
        'event_id': r'$undo',
        'sender': _frank,
        'redacts': r'$r1',
        'origin_server_ts': (9, 6).utc.millisecondsSinceEpoch,
        'content': {'redacts': r'$r1'},
      },
    ]);

    expect(await _shown(), isEmpty);
  });

  test('the newest first, 50 at most', () async {
    await _syncTeam([
      messageEvent((
        id: r'$mine',
        sender: threadOwner,
        body: 'the deck is ready',
        at: 8.utc,
      )),
      for (var i = 0; i < 55; i++)
        reactionEvent((
          id: '\$r$i',
          sender: _frank,
          target: r'$mine',
          key: 'e$i',
          at: (9, i).utc,
        )),
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
