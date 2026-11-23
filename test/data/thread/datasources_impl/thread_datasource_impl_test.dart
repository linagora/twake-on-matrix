import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/thread/datasources_impl/thread_datasource_impl.dart';
import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';
import 'package:twake_chat/domain/thread/exceptions/thread_exception.dart';

import '../../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../thread_fixtures.dart';

MatrixEvent _edit(String eventId, String target, int minute) => MatrixEvent(
  type: EventTypes.Message,
  content: {
    'msgtype': 'm.text',
    'body': '* edited',
    'm.new_content': {'msgtype': 'm.text', 'body': 'edited'},
    'm.relates_to': {'rel_type': RelationshipTypes.edit, 'event_id': target},
  },
  eventId: eventId,
  senderId: '@bob:example.com',
  originServerTs: DateTime.utc(2026, 11, 6, 10, minute),
);

MatrixEvent _reaction(String eventId, String target, int minute) => MatrixEvent(
  type: EventTypes.Reaction,
  content: {
    'm.relates_to': {
      'rel_type': RelationshipTypes.reaction,
      'event_id': target,
      'key': '👍',
    },
  },
  eventId: eventId,
  senderId: '@alice:example.com',
  originServerTs: DateTime.utc(2026, 11, 6, 10, minute),
);

/// THR-M-04: the thread screen loads the replies, and the edits and reactions
/// of the replies, through `/relations/<root>?recurse=true`, by pages, going
/// up the history.
void main() {
  late MockRoom room;
  late MockClient client;
  late ThreadDatasourceImpl datasource;

  PostExpectation<Future<GetRelatingEventsResponse>> whenRelations({
    String? from,
  }) => when(
    client.getRelatingEvents(
      threadRoomId,
      threadRootId,
      from: from,
      to: anyNamed('to'),
      limit: anyNamed('limit'),
      dir: anyNamed('dir'),
      recurse: anyNamed('recurse'),
    ),
  );

  void answerWith(List<MatrixEvent> chunk, {String? nextBatch, String? from}) =>
      whenRelations(from: from).thenAnswer(
        (_) async =>
            GetRelatingEventsResponse(chunk: chunk, nextBatch: nextBatch),
      );

  Future<ThreadRepliesPage<Event>> load({String? from, int? limit}) =>
      datasource.getReplies(
        threadRoomId,
        ThreadRepliesRequest(
          rootEventId: threadRootId,
          from: from,
          limit: limit ?? ThreadRepliesRequest.defaultPageSize,
        ),
      );

  setUp(() {
    room = MockRoom();
    client = MockClient();
    when(room.id).thenReturn(threadRoomId);
    when(room.client).thenReturn(client);
    when(room.encrypted).thenReturn(false);
    when(client.getRoomById(threadRoomId)).thenReturn(room);
    when(client.encryptionEnabled).thenReturn(true);
    when(client.encryption).thenReturn(FakeEncryption());
    datasource = ThreadDatasourceImpl(client);
  });

  test('the first page gives the most recent replies, oldest first', () async {
    // The server answers newest first when going backwards.
    answerWith([
      threadReply(r'$r3', 3),
      threadReply(r'$r2', 2),
      threadReply(r'$r1', 1),
    ], nextBatch: 'batch-1');

    final page = await load();

    expect(page.replies.map((event) => event.eventId), [
      r'$r1',
      r'$r2',
      r'$r3',
    ]);
    expect(page.nextBatch, 'batch-1');
    expect(page.canLoadMore, isTrue);
  });

  test('scrolling up reads every relation of the root, recursively, '
      'backwards from the batch token, a page at a time', () async {
    answerWith([threadReply(r'$r0', 0)], from: 'batch-1');

    final page = await load(from: 'batch-1', limit: 10);

    expect(page.replies.single.eventId, r'$r0');
    verify(
      client.getRelatingEvents(
        threadRoomId,
        threadRootId,
        from: 'batch-1',
        limit: 10,
        dir: Direction.b,
        recurse: true,
      ),
    ).called(1);
  });

  test('the replies are not read through the m.thread filter, which '
      'would leave the edits and reactions out', () async {
    answerWith([]);

    await load();

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

  test('the page keeps the replies and their edits and reactions, not the '
      'edits and reactions of the root', () async {
    // Newest first, as the server answers going backwards.
    answerWith([
      _reaction(r'$rootReaction', threadRootId, 5),
      _edit(r'$rootEdit', threadRootId, 4),
      _reaction(r'$r1Reaction', r'$r1', 3),
      _edit(r'$r1Edit', r'$r1', 2),
      threadReply(r'$r1', 1),
    ]);

    final page = await load();

    expect(page.replies.map((event) => event.eventId), [
      r'$r1',
      r'$r1Edit',
      r'$r1Reaction',
    ]);
  });

  test(
    'an edit or a reaction whose reply sits on the next, older page is '
    'still kept; the edits and reactions of the root are still left out',
    () async {
      // Newest first: the page boundary falls between $r1's edit and reaction
      // and $r1 itself (PR #3606 review).
      answerWith([
        _reaction(r'$rootReaction', threadRootId, 7),
        _reaction(r'$r1Reaction', r'$r1', 6),
        _edit(r'$r1Edit', r'$r1', 5),
        threadReply(r'$r2', 4),
      ], nextBatch: 'batch-1');
      answerWith([
        _edit(r'$rootEdit', threadRootId, 3),
        threadReply(r'$r1', 2),
      ], from: 'batch-1');

      final newest = await load();
      final older = await load(from: newest.nextBatch);
      final loaded = [
        ...newest.replies,
        ...older.replies,
      ].map((event) => event.eventId);

      expect(
        loaded,
        unorderedEquals([r'$r2', r'$r1Edit', r'$r1Reaction', r'$r1']),
      );
    },
  );

  test('the last page says there is nothing more to load', () async {
    answerWith([threadReply(r'$r0', 0)], from: 'batch-1');

    final page = await load(from: 'batch-1');

    expect(page.nextBatch, isNull);
    expect(page.canLoadMore, isFalse);
  });

  test('replies are events of the room, ready for the timeline', () async {
    answerWith([threadReply(r'$r1', 1)]);

    final page = await load();

    expect(page.replies.single.room, same(room));
    expect(page.replies.single.body, r'reply $r1');
  });

  test('replies of an encrypted room come back decrypted', () async {
    when(room.encrypted).thenReturn(true);
    answerWith([encryptedThreadReply(r'$r4', 4), threadReply(r'$r3', 3)]);

    final page = await load();

    expect(page.replies.map((e) => e.eventId), [r'$r3', r'$r4']);
    expect(page.replies.last.body, FakeEncryption.decryptedBody);
  });

  group('replies that cannot be decrypted stay as the server sent them', () {
    const cases = {
      'the room is not encrypted': (roomEncrypted: false, clientReady: true),
      'the client has no encryption': (roomEncrypted: true, clientReady: false),
    };

    cases.forEach((name, setup) {
      test(name, () async {
        when(room.encrypted).thenReturn(setup.roomEncrypted);
        when(client.encryptionEnabled).thenReturn(setup.clientReady);
        answerWith([encryptedThreadReply(r'$r4', 4)]);

        final page = await load();

        expect(page.replies.single.type, EventTypes.Encrypted);
      });
    });
  });

  test('a room the client does not know is a typed error, not an empty '
      'thread that reads as "no replies"', () async {
    when(client.getRoomById(threadRoomId)).thenReturn(null);

    await expectLater(
      load(),
      throwsA(
        isA<ThreadRoomNotFoundException>().having(
          (e) => e.roomId,
          'roomId',
          threadRoomId,
        ),
      ),
    );
    verifyNever(
      client.getRelatingEvents(
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

  test('a server error reaches the caller as a thread exception, '
      'not an SDK one', () async {
    whenRelations().thenThrow(
      MatrixException.fromJson({'errcode': 'M_UNKNOWN', 'error': 'boom'}),
    );

    await expectLater(
      load(),
      throwsA(
        allOf(
          isA<ThreadLoadFailedException>().having(
            (e) => e.roomId,
            'roomId',
            threadRoomId,
          ),
          isA<ThreadException>(),
          isNot(isA<MatrixException>()),
        ),
      ),
    );
  });

  group('a network failure reaches the caller as a thread exception, '
      'not a raw transport one', () {
    final failures = <String, Exception>{
      'the request times out': TimeoutException('relations'),
      'the connection is lost': http.ClientException('connection lost'),
      'the socket fails': const SocketException('no route to host'),
    };

    failures.forEach((name, failure) {
      test(name, () async {
        whenRelations().thenThrow(failure);

        await expectLater(
          load(),
          throwsA(
            isA<ThreadLoadFailedException>().having(
              (e) => e.roomId,
              'roomId',
              threadRoomId,
            ),
          ),
        );
      });
    });
  });

  test('a programming error is not hidden behind a thread exception', () async {
    whenRelations().thenThrow(StateError('bug'));

    await expectLater(load(), throwsA(isA<StateError>()));
  });

  test('an event whose m.relates_to is not a map does not fail the load, '
      'and the replies around it are still shown', () async {
    final malformed = MatrixEvent(
      type: EventTypes.Message,
      content: const {
        'msgtype': 'm.text',
        'body': 'odd',
        'm.relates_to': 'oops',
      },
      eventId: r'$odd',
      senderId: '@bob:example.com',
      originServerTs: DateTime.utc(2026, 11, 6, 10, 2),
    );
    answerWith([threadReply(r'$r3', 3), malformed, threadReply(r'$r1', 1)]);

    final page = await load();

    expect(
      page.replies.map((event) => event.eventId),
      containsAll([r'$r1', r'$r3']),
    );
  });
}
