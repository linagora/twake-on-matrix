import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../fake_client.dart';

/// Roast #1: the app sends threaded receipts only (`thread_id: main` or the
/// root id), so the unthreaded `receiptState.global` of an account that used
/// an older client stays on an old event. The SDK `Room.hasNewMessages` reads
/// that stale global receipt and reports new messages forever.
void main() {
  const roomId = '!room:example.com';
  const me = '@me:example.com';
  const bob = '@bob:example.com';
  const rootId = r'$root';

  late MockClient client;

  setUp(() {
    client = MockClient();
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

    test('a receipt in another thread does not read a reply of this one', () {
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
