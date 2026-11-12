import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/utils/activity/activity_reactions_store.dart';

import '../../data/datasource_impl/thread/thread_account.dart';

/// THR-M-12, slice 3 (review 2026-11-12): the server is asked for the
/// message of a live reaction at most 20 times at once, and the budget comes
/// back over time (20 per 10 minutes) instead of a hard cap for the session;
/// a message is asked once ever, found or not.
///
/// The store reads the time from `now` (a new optional argument of its
/// constructor), so the test moves the clock.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThreadAccount account;
  late ActivityReactionsStore store;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    account = ThreadAccount(RecordingHomeserver());
    await account.receiveRoomState(const []);
    // Every message asked is missing: only the requests count here.
    account.server.fail(_anyLookup, ServerError.notFound);
    now = DateTime.utc(2026, 11, 12, 10);
    store = ActivityReactionsStore(account, now: () => now);
  });

  /// A live reaction of Frank to [target], seen by the store.
  Future<void> react(String target) async {
    final room = account.getRoomById(teamRoomId)!;
    store.see(
      Event.fromJson({
        'type': EventTypes.Reaction,
        'event_id': '\$reaction${account.server.calls.length}$target',
        'sender': _frank,
        'origin_server_ts': now.millisecondsSinceEpoch,
        'content': {
          'm.relates_to': {
            'rel_type': RelationshipTypes.reaction,
            'event_id': target,
            'key': '❤️',
          },
        },
      }, room),
    );
    await _settle(account);
  }

  int asked(ThreadAccount account, [String? target]) => account.server
      .callsTo(target == null ? _anyLookup : _lookupOf(target))
      .length;

  Future<void> spendTheBudget() async {
    for (var i = 0; i < 20; i++) {
      await react('\$old$i');
    }
    expect(asked(account), 20);
  }

  test('once 20 messages were asked, a new one is not asked a minute '
      'later', () async {
    await spendTheBudget();

    now = now.add(const Duration(minutes: 1));
    await react(r'$late');

    expect(asked(account, r'$late'), 0);
  });

  test('ten minutes later, a new message is asked again', () async {
    await spendTheBudget();

    now = now.add(const Duration(minutes: 10, seconds: 1));
    await react(r'$later');

    expect(asked(account, r'$later'), 1);
  });

  test('a message not asked for want of budget is asked at its next '
      'reaction once the budget is back', () async {
    await spendTheBudget();
    await react(r'$waiting');
    expect(asked(account, r'$waiting'), 0);

    now = now.add(const Duration(minutes: 10, seconds: 1));
    await react(r'$waiting');

    expect(asked(account, r'$waiting'), 1);
  });

  test('a message the server did not find is not asked again, even once '
      'the budget is back', () async {
    await react(r'$gone');
    expect(asked(account, r'$gone'), 1);

    now = now.add(const Duration(minutes: 30));
    await react(r'$gone');

    expect(asked(account, r'$gone'), 1);
  });
}

const _frank = '@frank:example.org';

const _anyLookup = ServerRoute.get('rooms/$teamRoomId/event/');

ServerRoute _lookupOf(String eventId) =>
    ServerRoute.get('rooms/$teamRoomId/event/$eventId');

/// Lets the store handle what it was given: returns once the server got no
/// new request for 100 ms (2 s at most).
Future<void> _settle(ThreadAccount account) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  var count = -1;
  var quiet = 0;
  while (quiet < 5 && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final calls = account.server.calls.length;
    quiet = calls == count ? quiet + 1 : 0;
    count = calls;
  }
}
