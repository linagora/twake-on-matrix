import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';

import '../../usecase/room/send_text_message_interactor_test.mocks.dart';

/// THR-M-09 and THR-M-06: the local notification of a thread reply.
///
/// With `unread_thread_notifications`, the room counters leave the thread
/// messages out, and the thread counters of a sync land on `onSync`, after
/// `onEvent` fired for its events. So the decision for a reply cannot wait
/// for any counter: it is made from the reply and the follow state.
void main() {
  const roomId = '!room:example.com';
  const rootId = r'$root';
  const me = '@me:example.com';

  late MockRoom room;

  setUp(() {
    final client = MockClient();
    when(client.userID).thenReturn(me);
    room = MockRoom();
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    // What the room says before the thread counters land.
    when(room.notificationCount).thenReturn(0);
    when(room.highlightCount).thenReturn(0);
    when(room.pushRuleState).thenReturn(PushRuleState.notify);
  });

  Event reply({bool mentionsMe = false}) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': mentionsMe ? 'Me: look' : 'look',
      if (mentionsMe) ...{
        'format': 'org.matrix.custom.html',
        'formatted_body': '<a href="https://matrix.to/#/$me">Me</a>: look',
        'm.mentions': {
          'user_ids': [me],
        },
      },
      'm.relates_to': {
        'rel_type': RelationshipTypes.thread,
        'event_id': rootId,
        'is_falling_back': true,
      },
    },
    eventId: r'$reply',
    senderId: '@bob:example.com',
    originServerTs: DateTime.utc(2026, 11, 8, 10),
    room: room,
  );

  test('a reply in a followed thread notifies while the room counters are '
      'still 0', () {
    expect(
      ThreadRules.shouldNotifyThreadEvent(reply(), followed: true),
      isTrue,
    );
  });

  test('a reply that mentions the user notifies, in a thread they do not '
      'follow', () {
    expect(
      ThreadRules.shouldNotifyThreadEvent(
        reply(mentionsMe: true),
        followed: false,
      ),
      isTrue,
    );
  });

  test('a reply in a thread the user does not follow, without mention, does '
      'not notify', () {
    expect(
      ThreadRules.shouldNotifyThreadEvent(reply(), followed: false),
      isFalse,
    );
  });

  test('a reply of the thread open on screen does not notify', () {
    expect(
      ThreadRules.shouldNotifyThreadEvent(
        reply(mentionsMe: true),
        followed: true,
        activeThread: (roomId: roomId, threadRootId: rootId),
      ),
      isFalse,
    );
  });

  test('a reply of another thread of the same room still notifies', () {
    expect(
      ThreadRules.shouldNotifyThreadEvent(
        reply(),
        followed: true,
        activeThread: (roomId: roomId, threadRootId: r'$other_root'),
      ),
      isTrue,
    );
  });

  group('in a muted room', () {
    setUp(() {
      when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);
    });

    test('a reply in a followed thread does not notify', () {
      expect(
        ThreadRules.shouldNotifyThreadEvent(reply(), followed: true),
        isFalse,
      );
    });

    test('a reply that mentions the user notifies', () {
      expect(
        ThreadRules.shouldNotifyThreadEvent(
          reply(mentionsMe: true),
          followed: false,
        ),
        isTrue,
      );
    });
  });
}
