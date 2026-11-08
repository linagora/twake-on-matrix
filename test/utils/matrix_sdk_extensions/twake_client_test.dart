import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/twake_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('enables limited timeline history backfill before initialization', () {
    final client = TwakeClient('testclient', database: MockDatabase());

    expect(client.requestHistoryOnLimitedTimeline, isTrue);
  });

  /// THR-M-01: once deleted, a reply loses its thread relation; its id must
  /// be known before that, from the live timeline of any sender.
  test('a thread reply of the live timeline is remembered as one', () async {
    final client = TwakeClient('testclient', database: MockDatabase());
    final room = Room(id: '!room:example.org', client: client);

    client.onTimelineEvent.add(
      Event(
        type: EventTypes.Message,
        content: {
          'msgtype': 'm.text',
          'body': 'in the thread',
          'm.relates_to': {
            'rel_type': RelationshipTypes.thread,
            'event_id': r'$root',
            'is_falling_back': true,
          },
        },
        eventId: r'$reply',
        senderId: '@bob:example.org',
        originServerTs: DateTime.utc(2026, 11, 8),
        room: room,
      ),
    );
    await pumpEventQueue();

    expect(
      client.threadUnread.knownThreadReplyIds('!room:example.org'),
      contains(r'$reply'),
    );
  });
}
