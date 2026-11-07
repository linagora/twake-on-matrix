import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';

/// THR-M-06: the mobile sends threaded receipts only, like the web, so its
/// receipts on the room no longer clear the unread threads read on the web.
void main() {
  const roomId = '!room:example.com';
  const rootId = r'$root';

  late MockRoom room;
  late MockClient client;

  setUp(() {
    room = MockRoom();
    client = MockClient();
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    when(client.receiptsPublicByDefault).thenReturn(true);
  });

  void verifyNoUnthreadedReceipt() {
    verifyNever(client.postReceipt(any, any, any));
    verifyNever(
      client.setReadMarker(
        any,
        mFullyRead: anyNamed('mFullyRead'),
        mRead: argThat(isNotNull, named: 'mRead'),
        mReadPrivate: anyNamed('mReadPrivate'),
      ),
    );
    verifyNever(
      client.setReadMarker(
        any,
        mFullyRead: anyNamed('mFullyRead'),
        mRead: anyNamed('mRead'),
        mReadPrivate: argThat(isNotNull, named: 'mReadPrivate'),
      ),
    );
  }

  group('main timeline', () {
    test('reading the room sends a receipt on the main thread', () async {
      await room.setMainTimelineReadMarker(r'$last');

      verify(
        client.postReceipt(
          roomId,
          ReceiptType.mRead,
          r'$last',
          threadId: 'main',
        ),
      ).called(1);
      verifyNoUnthreadedReceipt();
    });

    test('m.fully_read keeps following the main timeline', () async {
      await room.setMainTimelineReadMarker(r'$last');

      verify(client.setReadMarker(roomId, mFullyRead: r'$last')).called(1);
    });

    test('with private receipts the main thread receipt is private', () async {
      when(client.receiptsPublicByDefault).thenReturn(false);

      await room.setMainTimelineReadMarker(r'$last');

      verify(
        client.postReceipt(
          roomId,
          ReceiptType.mReadPrivate,
          r'$last',
          threadId: 'main',
        ),
      ).called(1);
      verifyNever(
        client.postReceipt(
          any,
          ReceiptType.mRead,
          any,
          threadId: anyNamed('threadId'),
        ),
      );
      verifyNoUnthreadedReceipt();
    });
  });

  group('thread screen', () {
    test(
      'reading a thread sends a receipt with the root as thread id',
      () async {
        await room.setThreadReadMarker(
          threadRootId: rootId,
          eventId: r'$reply',
        );

        verify(
          client.postReceipt(
            roomId,
            ReceiptType.mRead,
            r'$reply',
            threadId: rootId,
          ),
        ).called(1);
        verifyNoUnthreadedReceipt();
      },
    );

    test('reading a thread does not move m.fully_read of the room', () async {
      await room.setThreadReadMarker(threadRootId: rootId, eventId: r'$reply');

      verifyNever(
        client.setReadMarker(
          any,
          mFullyRead: anyNamed('mFullyRead'),
          mRead: anyNamed('mRead'),
          mReadPrivate: anyNamed('mReadPrivate'),
        ),
      );
    });

    test('reading a thread sends nothing on the main thread', () async {
      await room.setThreadReadMarker(threadRootId: rootId, eventId: r'$reply');

      verifyNever(client.postReceipt(any, any, any, threadId: 'main'));
    });
  });

  group('Mark as read on a room', () {
    test('reads the main timeline and every unread thread', () async {
      await room.markRoomAndThreadsRead(
        mainEventId: r'$last',
        lastEventIdByThreadRootId: {r'$rootA': r'$a9', r'$rootB': r'$b3'},
      );

      verify(
        client.postReceipt(
          roomId,
          ReceiptType.mRead,
          r'$last',
          threadId: 'main',
        ),
      ).called(1);
      verify(
        client.postReceipt(
          roomId,
          ReceiptType.mRead,
          r'$a9',
          threadId: r'$rootA',
        ),
      ).called(1);
      verify(
        client.postReceipt(
          roomId,
          ReceiptType.mRead,
          r'$b3',
          threadId: r'$rootB',
        ),
      ).called(1);
      verifyNoUnthreadedReceipt();
    });
  });
}
