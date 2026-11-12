import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';

import '../../data/datasource_impl/thread/thread_account.dart';
import 'activity_test_support.dart';

/// THR-M-12, slice 3 (review 2026-11-12): with the threads turned off
/// (`AppConfig.threadsEnabled` false), the app shows no thread. A reaction
/// to a message the user wrote in a thread opens its room on the message,
/// not the thread. Through the real repositories of the account: where the
/// choice is made does not matter, the screen opened does.
void main() {
  late ThreadAccount account;

  // The sync of the account runs on the real clock, before the test.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppConfig.threadsEnabled = false;
    addTearDown(() => AppConfig.threadsEnabled = true);
    account = ThreadAccount(RecordingHomeserver());
    await account.receiveRoomState(const []);
    await account.receiveSync(_teamRoomWithReaction);
    // The reaction is read by the store of the account.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });

  testWidgets('a reaction to a message of the user in a thread opens the '
      'room on the message', (tester) async {
    await pumpActivityPage(
      tester,
      repository: null,
      account: account,
      settle: false,
    );
    await _letTheAccountAnswer(tester);

    await tester.tap(
      find.textContaining('I can take it', findRichText: true).first,
    );
    await _letTheAccountAnswer(tester);

    expect(
      find.text(
        openedText(
          const RoomRoute(roomid: teamRoomId, event: r'$my_reply').location,
        ),
      ),
      findsOneWidget,
    );
  });
}

/// The real repositories read the account and its fake server: their
/// futures run outside the fake clock of the test.
Future<void> _letTheAccountAnswer(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _frank = '@frank:example.org';

final _at = DateTime.now().subtract(const Duration(minutes: 5));

Map<String, Object?> _member(String userId, String name) => {
  'type': EventTypes.RoomMember,
  'state_key': userId,
  'sender': userId,
  'event_id': '\$member$userId',
  'origin_server_ts': 0,
  'content': {'membership': 'join', 'displayname': name},
};

final Map<String, Object?> _teamRoomWithReaction = {
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
              'origin_server_ts': 0,
              'content': {'name': 'Team'},
            },
            _member(threadOwner, 'Me Myself'),
            _member(_frank, 'Frank Moore'),
          ],
        },
        'timeline': {
          'events': [
            {
              'type': EventTypes.Message,
              'event_id': r'$my_reply',
              'sender': threadOwner,
              'origin_server_ts': _at.millisecondsSinceEpoch,
              'content': {
                'msgtype': 'm.text',
                'body': 'I can take it',
                'm.relates_to': {
                  'rel_type': RelationshipTypes.thread,
                  'event_id': lunchThread.rootEventId,
                  'is_falling_back': true,
                  'm.in_reply_to': {'event_id': lunchThread.rootEventId},
                },
              },
            },
            {
              'type': EventTypes.Reaction,
              'event_id': r'$thumbs',
              'sender': _frank,
              'origin_server_ts': _at.millisecondsSinceEpoch + 60000,
              'content': {
                'm.relates_to': {
                  'rel_type': RelationshipTypes.reaction,
                  'event_id': r'$my_reply',
                  'key': '👍',
                },
              },
            },
          ],
          'limited': false,
        },
      },
    },
  },
};
