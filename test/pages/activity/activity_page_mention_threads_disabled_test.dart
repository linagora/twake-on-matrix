import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';

import '../../data/datasource_impl/thread/thread_account.dart';
import 'activity_test_support.dart';

/// THR-M-12, slice 2 (review 2026-11-12): with the threads turned off
/// (`AppConfig.threadsEnabled` false), the app shows no thread. A mention
/// written in a thread opens its room on the message, not the thread.
/// Through the real repositories of the account: where the choice is made
/// does not matter, the screen opened does.
void main() {
  late ThreadAccount account;

  // The sync of the account runs on the real clock, before the test.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppConfig.threadsEnabled = false;
    addTearDown(() => AppConfig.threadsEnabled = true);
    account = ThreadAccount(RecordingHomeserver());
    await account.receiveRoomState(const []);
    await account.receiveSync(_teamRoom);
  });

  testWidgets('a mention in a thread opens the room on the message', (
    tester,
  ) async {
    account.server
      ..answer(const ServerRoute.get('notifications'), {
        'notifications': [
          {
            'actions': [
              'notify',
              {'set_tweak': 'highlight'},
            ],
            'event': _mentionInThread,
            'read': false,
            'room_id': teamRoomId,
            'ts': _mentionInThread['origin_server_ts'],
          },
        ],
      })
      ..answer(
        ServerRoute.get('rooms/$teamRoomId/event/${lunchThread.rootEventId}'),
        _lunchRoot,
      );

    await pumpActivityPage(
      tester,
      ActivityPageSetup(repository: null, account: account, settle: false),
    );
    await _letTheAccountAnswer(tester);
    await selectFilterWhileLoading(tester, 'Mentions');
    await _letTheAccountAnswer(tester);
    await tester.tap(find.textContaining('can you check?', findRichText: true));
    await _letTheAccountAnswer(tester);

    expect(
      find.text(
        openedText(
          const RoomRoute(roomid: teamRoomId, event: r'$ask').location,
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

const _dan = '@dan:example.org';

final _at = DateTime.now().subtract(const Duration(minutes: 5));

final Map<String, Object?> _lunchRoot = {
  'type': EventTypes.Message,
  'event_id': lunchThread.rootEventId,
  'sender': _dan,
  'room_id': teamRoomId,
  'origin_server_ts': _at.millisecondsSinceEpoch - 60000,
  'content': {'msgtype': 'm.text', 'body': 'Lunch on Friday?'},
};

final Map<String, Object?> _mentionInThread = {
  'type': EventTypes.Message,
  'event_id': r'$ask',
  'sender': _dan,
  'room_id': teamRoomId,
  'origin_server_ts': _at.millisecondsSinceEpoch,
  'content': {
    'msgtype': 'm.text',
    'body': '@me can you check?',
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': lunchThread.rootEventId,
      'is_falling_back': true,
      'm.in_reply_to': {'event_id': lunchThread.rootEventId},
    },
  },
};

final Map<String, Object?> _teamRoom = {
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
            {
              'type': EventTypes.RoomMember,
              'state_key': _dan,
              'sender': _dan,
              'event_id': r'$member_dan',
              'origin_server_ts': 0,
              'content': {'membership': 'join', 'displayname': 'Dan Brown'},
            },
          ],
        },
      },
    },
  },
};
