import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/services/message_splitter.dart';
import 'package:twake_chat/domain/services/room_send_queue_service.dart';
import 'package:twake_chat/domain/usecase/room/send_text_message_interactor.dart';

import 'send_text_message_interactor_test.mocks.dart';

/// THR-M-05: every text sent from the thread screen (text, mention, emoji,
/// command) carries the thread relation: `threadRootEventId` = root,
/// `threadLastEventId` = last event of the thread, and never `inReplyTo`,
/// which would make the SDK prepend a quote to the body.
void main() {
  const rootId = r'$root';
  const lastId = r'$last';

  late SendTextMessageInteractor interactor;
  late MockRoom room;

  PostExpectation<Future<String?>> whenSendTextEvent() => when(
    room.sendTextEvent(
      any,
      inReplyTo: anyNamed('inReplyTo'),
      editEventId: anyNamed('editEventId'),
      parseCommands: anyNamed('parseCommands'),
      threadRootEventId: anyNamed('threadRootEventId'),
      threadLastEventId: anyNamed('threadLastEventId'),
    ),
  );

  void verifyNoOtherSend() => verifyNever(
    room.sendTextEvent(
      any,
      inReplyTo: anyNamed('inReplyTo'),
      editEventId: anyNamed('editEventId'),
      parseCommands: anyNamed('parseCommands'),
      threadRootEventId: anyNamed('threadRootEventId'),
      threadLastEventId: anyNamed('threadLastEventId'),
    ),
  );

  setUp(() {
    interactor = SendTextMessageInteractor(
      splitter: const MessageSplitter(maxLength: 5),
      sendQueue: RoomSendQueueService(),
    );
    room = MockRoom();
    when(room.id).thenReturn('!room:example.org');
    final MockClient client = MockClient();
    when(room.client).thenReturn(client);
    when(client.commands).thenReturn({'me': (_, _) => null});
    whenSendTextEvent().thenAnswer((_) async => r'$sent');
  });

  test('a text sent in a thread carries the root and the last event', () async {
    await interactor.execute(
      room: room,
      text: 'hello',
      threadRootEventId: rootId,
      threadLastEventId: lastId,
    );

    // Omitted named arguments must be null: no inReplyTo.
    verify(
      room.sendTextEvent(
        'hello',
        parseCommands: false,
        threadRootEventId: rootId,
        threadLastEventId: lastId,
      ),
    ).called(1);
    verifyNoOtherSend();
  });

  test('a mention or an emoji is sent in the thread like any text', () async {
    const text = '@bob 🎉';
    interactor = SendTextMessageInteractor(
      splitter: const MessageSplitter(maxLength: 100),
      sendQueue: RoomSendQueueService(),
    );

    await interactor.execute(
      room: room,
      text: text,
      threadRootEventId: rootId,
      threadLastEventId: lastId,
    );

    verify(
      room.sendTextEvent(
        text,
        parseCommands: false,
        threadRootEventId: rootId,
        threadLastEventId: lastId,
      ),
    ).called(1);
  });

  test(
    'a reply quote is dropped in a thread: inReplyTo is never sent',
    () async {
      final MockEvent quoted = MockEvent();

      await interactor.execute(
        room: room,
        text: 'hello',
        inReplyTo: quoted,
        threadRootEventId: rootId,
        threadLastEventId: lastId,
      );

      verify(
        room.sendTextEvent(
          'hello',
          parseCommands: false,
          threadRootEventId: rootId,
          threadLastEventId: lastId,
        ),
      ).called(1);
      verifyNever(
        room.sendTextEvent(
          any,
          inReplyTo: argThat(isNotNull, named: 'inReplyTo'),
          editEventId: anyNamed('editEventId'),
          parseCommands: anyNamed('parseCommands'),
          threadRootEventId: anyNamed('threadRootEventId'),
          threadLastEventId: anyNamed('threadLastEventId'),
        ),
      );
    },
  );

  test(
    'a known command sent in a thread carries the thread relation',
    () async {
      const command = '/me waves';

      await interactor.execute(
        room: room,
        text: command,
        threadRootEventId: rootId,
        threadLastEventId: lastId,
      );

      verify(
        room.sendTextEvent(
          command,
          parseCommands: true,
          threadRootEventId: rootId,
          threadLastEventId: lastId,
        ),
      ).called(1);
      verifyNoOtherSend();
    },
  );

  test('every part of a long text stays in the thread, each one following '
      'the previous part', () async {
    // Twelve characters, three parts of five.
    var sent = 0;
    whenSendTextEvent().thenAnswer((_) async => '\$part${++sent}');

    await interactor.execute(
      room: room,
      text: 'abcdefghijkl',
      threadRootEventId: rootId,
      threadLastEventId: lastId,
    );

    verifyInOrder([
      room.sendTextEvent(
        'abcde',
        parseCommands: false,
        threadRootEventId: rootId,
        threadLastEventId: lastId,
      ),
      room.sendTextEvent(
        'fghij',
        parseCommands: false,
        threadRootEventId: rootId,
        threadLastEventId: r'$part1',
      ),
      room.sendTextEvent(
        'kl',
        parseCommands: false,
        threadRootEventId: rootId,
        threadLastEventId: r'$part2',
      ),
    ]);
    verifyNoOtherSend();
  });

  test('a text sent outside a thread carries no thread relation', () async {
    await interactor.execute(room: room, text: 'hello');

    verify(room.sendTextEvent('hello', parseCommands: false)).called(1);
    verifyNoOtherSend();
  });
}
