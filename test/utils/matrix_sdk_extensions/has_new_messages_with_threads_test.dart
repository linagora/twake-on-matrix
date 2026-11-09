import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../fake_client.dart';

/// THR-M-06, spec §4 « Reçus ».
///
/// The app sends threaded receipts only (`thread_id: main` or the
/// root id), so the unthreaded `receiptState.global` of an account that used
/// an older client stays on an old event. The SDK `Room.hasNewMessages` reads
/// that stale global receipt and reports new messages forever.
///
/// THR-M-06 badge rule: a reply of a thread the user does not follow counts
/// only on its card, unless it mentions the user.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const roomId = '!room:example.com';
  const me = '@me:example.com';
  const bob = '@bob:example.com';
  const rootId = r'$root';

  late _ThreadClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = _ThreadClient();
    when(client.clientName).thenReturn('account-a');
    when(client.userID).thenReturn(me);
    // Event.receipts of the SDK looks the user up in the database.
    when(client.database).thenReturn(MockDatabase());
    when(
      client.roomPreviewLastEvents,
    ).thenReturn({EventTypes.Message, EventTypes.Encrypted});
  });

  DateTime at(int minute) => DateTime.utc(2026, 11, 6, 10, minute);

  LatestReceiptStateData receipt(String eventId, int minute) =>
      LatestReceiptStateData(eventId, at(minute).millisecondsSinceEpoch);

  LatestReceiptStateForTimeline own(LatestReceiptStateData data) =>
      LatestReceiptStateForTimeline(
        ownPrivate: null,
        ownPublic: data,
        latestOwnReceipt: data,
        otherUsers: {},
      );

  /// An account that used an unthreaded client long ago: its global receipt
  /// is on an event of last week and never moves again.
  LatestReceiptStateForTimeline staleGlobal() => own(
    LatestReceiptStateData(
      r'$old',
      DateTime.utc(2026, 10, 30).millisecondsSinceEpoch,
    ),
  );

  /// Server counters of the thread [root], and whether the user follows it.
  void threadCounters(
    String root, {
    required bool followed,
    int notifications = 1,
    int highlights = 0,
  }) {
    client.threadUnread.apply({
      roomId: {
        root: (notificationCount: notifications, highlightCount: highlights),
      },
    });
    if (followed) client.threadUnread.markFollowed(roomId, root);
  }

  Map<String, Object?> threadRelation(String root) => {
    'rel_type': RelationshipTypes.thread,
    'event_id': root,
    'is_falling_back': true,
  };

  Room roomWith({
    required LatestReceiptState receipts,
    required Event Function(Room room) lastEvent,
  }) {
    final room = Room(id: roomId, client: client, receiptState: receipts);
    room.lastEvent = lastEvent(room);
    return room;
  }

  Event message(
    Room room, {
    String eventId = r'$last',
    int minute = 5,
    String sender = bob,
    String type = EventTypes.Message,
    Map<String, Object?>? relatesTo,
  }) => Event(
    type: type,
    content: {'msgtype': 'm.text', 'body': 'hello', 'm.relates_to': ?relatesTo},
    eventId: eventId,
    senderId: sender,
    originServerTs: at(minute),
    room: room,
  );

  group('a stale unthreaded receipt does not keep the room unread', () {
    test('a main receipt on the last event reads the room', () {
      final room = roomWith(
        receipts: LatestReceiptState(
          global: staleGlobal(),
          mainThread: own(receipt(r'$last', 6)),
        ),
        lastEvent: (room) => message(room),
      );

      // The hostile condition: the SDK is fooled by the stale global receipt.
      expect(room.hasNewMessages, isTrue);
      expect(room.hasNewMessagesWithThreads, isFalse);
    });

    test('a main receipt newer than the last event reads the room, even on '
        'another event', () {
      // The receipt is on an event the client does not show (a reaction, an
      // edit) but it came after the last message.
      final room = roomWith(
        receipts: LatestReceiptState(
          global: staleGlobal(),
          mainThread: own(receipt(r'$other', 7)),
        ),
        lastEvent: (room) => message(room),
      );

      expect(room.hasNewMessagesWithThreads, isFalse);
    });

    test('a thread reply read in its thread reads the room', () {
      threadCounters(rootId, followed: true, notifications: 0);
      final room = roomWith(
        receipts: LatestReceiptState(
          global: staleGlobal(),
          mainThread: own(receipt(r'$before', 1)),
          byThread: {rootId: own(receipt(r'$reply', 6))},
        ),
        lastEvent: (room) => message(
          room,
          eventId: r'$reply',
          relatesTo: {
            'rel_type': RelationshipTypes.thread,
            'event_id': rootId,
            'is_falling_back': true,
          },
        ),
      );

      expect(room.hasNewMessagesWithThreads, isFalse);
    });
    test('an unthreaded receipt on the last event still reads the room', () {
      // A client of the account that still sends unthreaded receipts.
      final room = roomWith(
        receipts: LatestReceiptState(
          global: own(receipt(r'$last', 6)),
          mainThread: own(receipt(r'$before', 1)),
        ),
        lastEvent: (room) => message(room),
      );

      expect(room.hasNewMessagesWithThreads, isFalse);
    });
  });

  group('new messages are still reported', () {
    test('a main receipt older than the last event leaves the room unread', () {
      final room = roomWith(
        receipts: LatestReceiptState(
          global: staleGlobal(),
          mainThread: own(receipt(r'$before', 1)),
        ),
        lastEvent: (room) => message(room),
      );

      expect(room.hasNewMessagesWithThreads, isTrue);
    });

    test('a room without any receipt of the user is unread', () {
      final room = roomWith(
        receipts: LatestReceiptState.empty(),
        lastEvent: (room) => message(room),
      );

      expect(room.hasNewMessagesWithThreads, isTrue);
    });

    test('a receipt in another thread does not read a reply of a followed '
        'thread', () {
      threadCounters(rootId, followed: true);
      final room = roomWith(
        receipts: LatestReceiptState(
          global: staleGlobal(),
          mainThread: own(receipt(r'$before', 1)),
          byThread: {r'$another_root': own(receipt(r'$elsewhere', 9))},
        ),
        lastEvent: (room) => message(
          room,
          eventId: r'$reply',
          relatesTo: {
            'rel_type': RelationshipTypes.thread,
            'event_id': rootId,
            'is_falling_back': true,
          },
        ),
      );

      expect(room.hasNewMessagesWithThreads, isTrue);
    });
  });

  group('a reply in a thread the user does not follow', () {
    Room roomWithUnreadReply() => roomWith(
      // Read up to before the reply, everywhere.
      receipts: LatestReceiptState(
        global: staleGlobal(),
        mainThread: own(receipt(r'$before', 1)),
        byThread: {rootId: own(receipt(r'$older_reply', 2))},
      ),
      lastEvent: (room) =>
          message(room, eventId: r'$reply', relatesTo: threadRelation(rootId)),
    );

    test('is not a new message of the room', () {
      threadCounters(rootId, followed: false);

      expect(roomWithUnreadReply().hasNewMessagesWithThreads, isFalse);
    });

    test('is not a new message of the room in an E2EE room, while it cannot '
        'be decrypted', () {
      // `m.relates_to` stays in clear on `m.room.encrypted`.
      threadCounters(rootId, followed: false);
      final room = roomWith(
        receipts: LatestReceiptState(
          global: staleGlobal(),
          mainThread: own(receipt(r'$before', 1)),
        ),
        lastEvent: (room) => Event(
          type: EventTypes.Encrypted,
          content: {
            'algorithm': 'm.megolm.v1.aes-sha2',
            'ciphertext': 'AwgA',
            'session_id': 'unknown',
            'm.relates_to': threadRelation(rootId),
          },
          eventId: r'$reply',
          senderId: bob,
          originServerTs: at(5),
          room: room,
        ),
      );

      expect(room.hasNewMessagesWithThreads, isFalse);
    });

    test('that mentions the user is a new message of the room', () {
      threadCounters(rootId, followed: false, highlights: 1);

      expect(roomWithUnreadReply().hasNewMessagesWithThreads, isTrue);
    });

    test('is a new message once the user follows the thread', () {
      threadCounters(rootId, followed: true);

      expect(roomWithUnreadReply().hasNewMessagesWithThreads, isTrue);
    });
  });

  /// THR-M-09, MSC3771: an own receipt with `thread_id: main` reads the main
  /// timeline only. A thread reply is read by the receipt of its thread or
  /// by an unthreaded one, never by a `main` one, however recent.
  group('the last event is a reply of a followed thread', () {
    Room roomWithLastReply(LatestReceiptState receipts) => roomWith(
      receipts: receipts,
      lastEvent: (room) => message(
        room,
        eventId: r'$reply',
        minute: 5,
        relatesTo: threadRelation(rootId),
      ),
    );

    setUp(() => threadCounters(rootId, followed: true));

    test('a newer own main receipt does not read it: the room still has new '
        'messages', () {
      final room = roomWithLastReply(
        LatestReceiptState(
          global: staleGlobal(),
          mainThread: own(receipt(r'$main_after', 7)),
        ),
      );

      expect(room.hasNewMessagesWithThreads, isTrue);
    });

    test('a newer own main receipt and an older receipt of the thread: the '
        'room still has new messages', () {
      final room = roomWithLastReply(
        LatestReceiptState(
          global: staleGlobal(),
          mainThread: own(receipt(r'$main_after', 7)),
          byThread: {rootId: own(receipt(r'$older_reply', 2))},
        ),
      );

      expect(room.hasNewMessagesWithThreads, isTrue);
    });

    test('a newer own receipt of the thread reads it', () {
      final room = roomWithLastReply(
        LatestReceiptState(
          global: staleGlobal(),
          mainThread: own(receipt(r'$main_after', 7)),
          byThread: {rootId: own(receipt(r'$reply', 6))},
        ),
      );

      expect(room.hasNewMessagesWithThreads, isFalse);
    });

    test('a newer unthreaded own receipt reads it', () {
      // A client of the account that still sends unthreaded receipts.
      final room = roomWithLastReply(
        LatestReceiptState(
          global: own(receipt(r'$reply', 6)),
          mainThread: own(receipt(r'$before', 1)),
        ),
      );

      expect(room.hasNewMessagesWithThreads, isFalse);
    });
  });

  group('rules kept from the SDK', () {
    test('the last event sent by the user is not a new message', () {
      final room = roomWith(
        receipts: LatestReceiptState(global: staleGlobal()),
        lastEvent: (room) => message(room, sender: me),
      );

      expect(room.hasNewMessagesWithThreads, isFalse);
    });

    test('a last event of a type not shown in the preview is not a new '
        'message', () {
      final room = roomWith(
        receipts: LatestReceiptState(global: staleGlobal()),
        lastEvent: (room) => message(room, type: EventTypes.RoomMember),
      );

      expect(room.hasNewMessagesWithThreads, isFalse);
    });

    test('a room without last event has no new message', () {
      final room = Room(
        id: roomId,
        client: client,
        receiptState: LatestReceiptState(global: staleGlobal()),
      );

      expect(room.hasNewMessagesWithThreads, isFalse);
    });
  });
}

/// A client that keeps the thread counters, like [TwakeClient].
class _ThreadClient extends MockClient implements ThreadUnreadStoreOwner {
  @override
  late final ThreadUnreadStore threadUnread = ThreadUnreadStore(client: this);
}
