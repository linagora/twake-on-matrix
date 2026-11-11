import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/thread/repositories/thread_repository_impl.dart';
import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';

import '../../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';

/// Decrypts every event into the text message [decryptedBody].
class _FakeEncryption extends Fake implements Encryption {
  static const decryptedBody = 'decrypted reply';

  @override
  Future<Event> decryptRoomEvent(
    Event event, {
    bool store = false,
    EventUpdateType updateType = EventUpdateType.timeline,
  }) async => Event(
    type: EventTypes.Message,
    content: const {'msgtype': 'm.text', 'body': decryptedBody},
    eventId: event.eventId,
    senderId: event.senderId,
    originServerTs: event.originServerTs,
    room: event.room,
  );
}

/// A reply of [rootId] stored encrypted: `/relations` returns it as is.
MatrixEvent _encryptedReply(String eventId, {required String rootId}) =>
    MatrixEvent(
      type: EventTypes.Encrypted,
      content: {
        'algorithm': 'm.megolm.v1.aes-sha2',
        'ciphertext': 'AwgA',
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': rootId,
        },
      },
      eventId: eventId,
      senderId: '@bob:example.com',
      originServerTs: DateTime.utc(2026, 11, 6, 10, 4),
    );

/// THR-M-04: the thread screen loads the replies through
/// `/relations/<root>/m.thread`, by pages, going up the history.
void main() {
  const roomId = '!room:example.com';
  const rootId = r'$root';

  late MockRoom room;
  late MockClient client;
  late ThreadRepositoryImpl interactor;

  MatrixEvent reply(String eventId, int minute) => MatrixEvent(
    type: EventTypes.Message,
    content: {
      'msgtype': 'm.text',
      'body': 'reply $eventId',
      'm.relates_to': {
        'rel_type': RelationshipTypes.thread,
        'event_id': rootId,
        'is_falling_back': true,
      },
    },
    eventId: eventId,
    senderId: '@bob:example.com',
    originServerTs: DateTime.utc(2026, 11, 6, 10, minute),
  );

  PostExpectation<Future<GetRelatingEventsWithRelTypeResponse>> whenRelations({
    String? from,
  }) => when(
    client.getRelatingEventsWithRelType(
      roomId,
      rootId,
      RelationshipTypes.thread,
      from: from,
      to: anyNamed('to'),
      limit: anyNamed('limit'),
      dir: anyNamed('dir'),
      recurse: anyNamed('recurse'),
    ),
  );

  setUp(() {
    room = MockRoom();
    client = MockClient();
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    when(client.getRoomById(roomId)).thenReturn(room);
    interactor = ThreadRepositoryImpl(client);
  });

  test('the first page gives the most recent replies, oldest first', () async {
    // The server answers newest first when going backwards.
    whenRelations().thenAnswer(
      (_) async => GetRelatingEventsWithRelTypeResponse(
        chunk: [reply(r'$r3', 3), reply(r'$r2', 2), reply(r'$r1', 1)],
        nextBatch: 'batch-1',
      ),
    );

    final page = await interactor.getReplies(
      roomId,
      const ThreadRepliesRequest(rootEventId: rootId),
    );

    expect(page.replies.map((event) => event.eventId), [
      r'$r1',
      r'$r2',
      r'$r3',
    ]);
    expect(page.nextBatch, 'batch-1');
  });

  test(
    'the history is read going backwards from the most recent reply',
    () async {
      whenRelations().thenAnswer(
        (_) async => GetRelatingEventsWithRelTypeResponse(chunk: []),
      );

      await interactor.getReplies(
        roomId,
        const ThreadRepliesRequest(rootEventId: rootId),
      );

      verify(
        client.getRelatingEventsWithRelType(
          roomId,
          rootId,
          RelationshipTypes.thread,
          limit: anyNamed('limit'),
          dir: Direction.b,
          recurse: anyNamed('recurse'),
        ),
      ).called(1);
    },
  );

  test('scrolling up loads the next page from the batch token', () async {
    whenRelations(from: 'batch-1').thenAnswer(
      (_) async =>
          GetRelatingEventsWithRelTypeResponse(chunk: [reply(r'$r0', 0)]),
    );

    final page = await interactor.getReplies(
      roomId,
      const ThreadRepliesRequest(rootEventId: rootId, from: 'batch-1'),
    );

    expect(page.replies.single.eventId, r'$r0');
    verify(
      client.getRelatingEventsWithRelType(
        roomId,
        rootId,
        RelationshipTypes.thread,
        from: 'batch-1',
        limit: anyNamed('limit'),
        dir: Direction.b,
        recurse: anyNamed('recurse'),
      ),
    ).called(1);
  });

  test('the last page says there is nothing more to load', () async {
    whenRelations(from: 'batch-1').thenAnswer(
      (_) async =>
          GetRelatingEventsWithRelTypeResponse(chunk: [reply(r'$r0', 0)]),
    );

    final page = await interactor.getReplies(
      roomId,
      const ThreadRepliesRequest(rootEventId: rootId, from: 'batch-1'),
    );

    expect(page.nextBatch, isNull);
    expect(page.canLoadMore, isFalse);
  });

  test('a page with a next batch can load more', () async {
    whenRelations().thenAnswer(
      (_) async => GetRelatingEventsWithRelTypeResponse(
        chunk: [reply(r'$r5', 5)],
        nextBatch: 'batch-2',
      ),
    );

    final page = await interactor.getReplies(
      roomId,
      const ThreadRepliesRequest(rootEventId: rootId),
    );

    expect(page.canLoadMore, isTrue);
  });

  test('replies are events of the room, ready for the timeline', () async {
    whenRelations().thenAnswer(
      (_) async =>
          GetRelatingEventsWithRelTypeResponse(chunk: [reply(r'$r1', 1)]),
    );

    final page = await interactor.getReplies(
      roomId,
      const ThreadRepliesRequest(rootEventId: rootId),
    );

    expect(page.replies.single.room, same(room));
    expect(page.replies.single.body, r'reply $r1');
  });

  test(
    'a server error reaches the caller so the screen can offer a retry',
    () async {
      whenRelations().thenThrow(
        MatrixException.fromJson({'errcode': 'M_UNKNOWN', 'error': 'boom'}),
      );

      expect(
        interactor.getReplies(
          roomId,
          const ThreadRepliesRequest(rootEventId: rootId),
        ),
        throwsA(isA<MatrixException>()),
      );
    },
  );

  /// The thread screen also needs the edits and reactions of the replies:
  /// it reads every relation of the root, recursively.
  group('with the relations of the replies', () {
    setUp(() {
      when(room.encrypted).thenReturn(true);
      when(client.encryptionEnabled).thenReturn(true);
      when(client.encryption).thenReturn(_FakeEncryption());
      when(
        client.getRelatingEvents(
          roomId,
          rootId,
          from: anyNamed('from'),
          to: anyNamed('to'),
          limit: anyNamed('limit'),
          dir: anyNamed('dir'),
          recurse: anyNamed('recurse'),
        ),
      ).thenAnswer(
        (_) async => GetRelatingEventsResponse(
          chunk: [
            _encryptedReply(r'$r4', rootId: rootId),
            reply(r'$r3', 3),
          ],
          nextBatch: 'batch-2',
        ),
      );
    });

    Future<ThreadRepliesPage> loadFrom(String from) => interactor.getReplies(
      roomId,
      ThreadRepliesRequest(
        rootEventId: rootId,
        from: from,
        withRelations: true,
      ),
    );

    test('reads every relation of the root, recursively, going backwards '
        'from the batch token', () async {
      await loadFrom('batch-1');

      verify(
        client.getRelatingEvents(
          roomId,
          rootId,
          from: 'batch-1',
          limit: anyNamed('limit'),
          dir: Direction.b,
          recurse: true,
        ),
      ).called(1);
      verifyNever(
        client.getRelatingEventsWithRelType(
          any,
          any,
          any,
          from: anyNamed('from'),
          to: anyNamed('to'),
          limit: anyNamed('limit'),
          dir: anyNamed('dir'),
          recurse: anyNamed('recurse'),
        ),
      );
    });

    test('gives the page oldest first, encrypted replies decrypted', () async {
      final page = await loadFrom('batch-1');

      expect(page.replies.map((e) => e.eventId), [r'$r3', r'$r4']);
      expect(page.replies.last.body, _FakeEncryption.decryptedBody);
      expect(page.nextBatch, 'batch-2');
    });
  });
}
