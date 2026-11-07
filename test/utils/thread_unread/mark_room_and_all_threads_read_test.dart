import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../fake_client.dart';

/// Stored events of a room, newest first, paged like the SDK database.
class _StoredEventsDatabase extends MockDatabase {
  _StoredEventsDatabase(this.events);

  final List<Event> events;

  @override
  Future<List<Event>> getEventList(
    Room room, {
    int start = 0,
    bool onlySending = false,
    int? limit,
  }) async {
    final stored = events
        .where((e) => !onlySending || e.status.isSending)
        .skip(start);
    return (limit == null ? stored : stored.take(limit)).toList();
  }
}

/// THR-M-06 « Marquer comme lu ».
///
/// "Mark as read" on a room sends its main receipt on the
/// newest main timeline event, found among the stored events of the room,
/// even when the most recent ones are all thread replies.
void main() {
  const roomId = '!room:example.com';
  const rootId = r'$root';
  const me = '@me:example.com';
  const bob = '@bob:example.com';

  late MockClient client;
  late Room room;

  DateTime at(int minute) =>
      DateTime.utc(2026, 11, 6, 10).add(Duration(minutes: minute));

  Event threadReply(int i, int minute) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': 'reply $i',
      'm.relates_to': {
        'rel_type': RelationshipTypes.thread,
        'event_id': rootId,
        'is_falling_back': true,
      },
    },
    eventId: '\$thread_reply_$i',
    senderId: bob,
    originServerTs: at(minute),
    room: room,
  );

  Event mainMessage(String eventId, int minute) => Event(
    type: EventTypes.Message,
    content: {'msgtype': 'm.text', 'body': 'main $eventId'},
    eventId: eventId,
    senderId: bob,
    originServerTs: at(minute),
    room: room,
  );

  setUp(() {
    client = MockClient();
    when(client.userID).thenReturn(me);
    when(client.receiptsPublicByDefault).thenReturn(true);
    when(
      client.roomPreviewLastEvents,
    ).thenReturn({EventTypes.Message, EventTypes.Encrypted});
    room = Room(id: roomId, client: client);
  });

  test('the main receipt lands on the main message hidden behind 40 thread '
      'replies', () async {
    // Newest first: 40 replies in a busy thread, then the last message of
    // the main timeline, then older history.
    final stored = [
      for (var i = 0; i < 40; i++) threadReply(i, 100 - i),
      mainMessage(r'$main', 50),
      mainMessage(r'$older_main', 40),
      mainMessage(rootId, 30),
    ];
    when(client.database).thenReturn(_StoredEventsDatabase(stored));
    room.lastEvent = stored.first;

    await room.markRoomAndAllThreadsRead();

    verify(
      client.postReceipt(roomId, ReceiptType.mRead, r'$main', threadId: 'main'),
    ).called(1);
    verifyNever(
      client.postReceipt(
        any,
        any,
        argThat(startsWith(r'$thread_reply_')),
        threadId: 'main',
      ),
    );
  });

  test('a main message behind a few thread replies gets the main '
      'receipt', () async {
    final stored = [
      for (var i = 0; i < 3; i++) threadReply(i, 100 - i),
      mainMessage(r'$main', 50),
      mainMessage(rootId, 30),
    ];
    when(client.database).thenReturn(_StoredEventsDatabase(stored));
    room.lastEvent = stored.first;

    await room.markRoomAndAllThreadsRead();

    verify(
      client.postReceipt(roomId, ReceiptType.mRead, r'$main', threadId: 'main'),
    ).called(1);
  });
}
