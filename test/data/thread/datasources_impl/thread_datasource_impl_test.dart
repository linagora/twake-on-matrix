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
}
