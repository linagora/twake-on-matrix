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
    // Nothing read yet, unless a test says otherwise.
    when(room.receiptState).thenReturn(LatestReceiptState.empty());
  });

  /// When [reply] was sent.
  final replySentAt = DateTime.utc(2026, 11, 8, 10);

  /// The user's own receipt, sent at [at].
  LatestReceiptStateForTimeline ownReceiptAt(DateTime at) =>
      LatestReceiptStateForTimeline(
        ownPrivate: null,
        ownPublic: LatestReceiptStateData(r'$read', at.millisecondsSinceEpoch),
        latestOwnReceipt: LatestReceiptStateData(
          r'$read',
          at.millisecondsSinceEpoch,
        ),
        otherUsers: {},
      );

  void receipts({
    DateTime? global,
    DateTime? main,
    Map<String, DateTime> byThread = const {},
    Map<String, DateTime> othersInThread = const {},
  }) {
    when(room.receiptState).thenReturn(
      LatestReceiptState(
        global: global == null
            ? LatestReceiptStateForTimeline.empty()
            : ownReceiptAt(global),
        mainThread: main == null ? null : ownReceiptAt(main),
        byThread: {
          for (final entry in byThread.entries)
            entry.key: ownReceiptAt(entry.value),
          for (final entry in othersInThread.entries)
            entry.key: LatestReceiptStateForTimeline(
              ownPrivate: null,
              ownPublic: null,
              latestOwnReceipt: null,
              otherUsers: {
                '@alice:example.com': LatestReceiptStateData(
                  r'$read',
                  entry.value.millisecondsSinceEpoch,
                ),
              },
            ),
        },
      ),
    );
  }

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
    originServerTs: replySentAt,
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

  /// THR-M-09: a catch-up sync, or a reply read on another
  /// device, brings replies the user has read already. Their own receipt in
  /// the thread, or a newer unthreaded one, says so (MSC3771: a `main`
  /// receipt does not cover threads); the follow state and a mention do not
  /// bring the notification back.
  group('a reply the user has read already', () {
    const later = Duration(minutes: 1);

    test('does not notify when the own receipt of the thread is on it', () {
      receipts(byThread: {rootId: replySentAt});

      expect(
        ThreadRules.shouldNotifyThreadEvent(
          reply(mentionsMe: true),
          followed: true,
        ),
        isFalse,
      );
    });

    test('does not notify when the own receipt of the thread is newer', () {
      receipts(byThread: {rootId: replySentAt.add(later)});

      expect(
        ThreadRules.shouldNotifyThreadEvent(reply(), followed: true),
        isFalse,
      );
    });

    test('does not notify when an unthreaded own receipt is newer than the '
        'one of the thread', () {
      receipts(
        global: replySentAt.add(later),
        byThread: {rootId: replySentAt.subtract(later)},
      );

      expect(
        ThreadRules.shouldNotifyThreadEvent(reply(), followed: true),
        isFalse,
      );
    });

    test('MSC3771: a newer own main receipt does not read a thread reply, '
        'which still notifies', () {
      // A `main` receipt covers the main timeline only; a thread reply is
      // read by the receipt of its thread or by an unthreaded one.
      receipts(
        main: replySentAt.add(later),
        byThread: {rootId: replySentAt.subtract(later)},
      );

      expect(
        ThreadRules.shouldNotifyThreadEvent(reply(), followed: true),
        isTrue,
      );
    });

    test('a newer reply than every own receipt still notifies', () {
      receipts(
        global: replySentAt.subtract(later),
        main: replySentAt.subtract(later),
        byThread: {rootId: replySentAt.subtract(later)},
      );

      expect(
        ThreadRules.shouldNotifyThreadEvent(reply(), followed: true),
        isTrue,
      );
    });

    test('the own receipt of another thread does not read this one', () {
      receipts(byThread: {r'$other_root': replySentAt.add(later)});

      expect(
        ThreadRules.shouldNotifyThreadEvent(reply(), followed: true),
        isTrue,
      );
    });

    test('the receipt of another user does not read it for the user', () {
      receipts(othersInThread: {rootId: replySentAt.add(later)});

      expect(
        ThreadRules.shouldNotifyThreadEvent(reply(), followed: true),
        isTrue,
      );
    });
  });

  /// THR-M-07 (P1: following = wrote the root or replied). On a
  /// new device the store knows no thread yet: a root the user wrote makes
  /// the thread followed for this decision. The caller passes the sender of
  /// the root (`rootSenderId`), which it reads from the root event.
  group('a thread whose root the user wrote', () {
    test('notifies a reply although the store does not know the thread '
        'yet', () {
      expect(
        ThreadRules.shouldNotifyThreadEvent(
          reply(),
          followed: false,
          rootSenderId: me,
        ),
        isTrue,
      );
    });

    test('a root of another user, in a thread not followed, does not '
        'notify', () {
      expect(
        ThreadRules.shouldNotifyThreadEvent(
          reply(),
          followed: false,
          rootSenderId: '@alice:example.com',
        ),
        isFalse,
      );
    });

    test('a reply already read does not notify', () {
      receipts(byThread: {rootId: replySentAt});

      expect(
        ThreadRules.shouldNotifyThreadEvent(
          reply(),
          followed: false,
          rootSenderId: me,
        ),
        isFalse,
      );
    });

    test('in a muted room, a reply without mention does not notify', () {
      when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);

      expect(
        ThreadRules.shouldNotifyThreadEvent(
          reply(),
          followed: false,
          rootSenderId: me,
        ),
        isFalse,
      );
    });
  });
}
