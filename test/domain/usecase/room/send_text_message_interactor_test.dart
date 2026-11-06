import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/services/message_splitter.dart';
import 'package:twake_chat/domain/services/room_send_queue_service.dart';
import 'package:twake_chat/domain/usecase/room/send_text_message_interactor.dart';

import 'send_text_message_interactor_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>(), MockSpec<Client>(), MockSpec<Event>()])
void main() {
  group('SendTextMessageInteractor', () {
    // Twelve characters, three parts of five.
    const String longText = 'abcdefghijkl';
    const String editEventId = r'$edited';
    late SendTextMessageInteractor interactor;
    late MockRoom room;

    Event mediaEvent(Map<String, Object?> content) => Event(
      content: content,
      type: EventTypes.Message,
      eventId: editEventId,
      senderId: '@alice:example.org',
      originServerTs: DateTime(2026),
      room: room,
    );

    Event textEvent() =>
        mediaEvent({'msgtype': MessageTypes.Text, 'body': 'before'});

    PostExpectation<Future<String?>> whenSendTextEvent() => when(
      room.sendTextEvent(
        any,
        inReplyTo: anyNamed('inReplyTo'),
        editEventId: anyNamed('editEventId'),
        parseCommands: anyNamed('parseCommands'),
      ),
    );

    void verifyNoOtherSend() {
      verifyNever(
        room.sendTextEvent(
          any,
          inReplyTo: anyNamed('inReplyTo'),
          editEventId: anyNamed('editEventId'),
          parseCommands: anyNamed('parseCommands'),
        ),
      );
      verifyNever(room.sendEvent(any, editEventId: anyNamed('editEventId')));
    }

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
      whenSendTextEvent().thenAnswer((_) async => r'$event');
      when(
        room.sendEvent(any, editEventId: anyNamed('editEventId')),
      ).thenAnswer((_) async => r'$event');
    });

    test(
      'should send the text once as plain text when it fits in one part',
      () async {
        // Arrange
        const String text = 'hello';

        // Act
        await interactor.execute(room: room, text: text);

        // Assert
        verify(room.sendTextEvent(text, parseCommands: false)).called(1);
        verifyNoOtherSend();
      },
    );

    test(
      'should send every part in order when the text exceeds the limit',
      () async {
        // Act
        await interactor.execute(room: room, text: longText);

        // Assert
        verifyInOrder([
          room.sendTextEvent('abcde', parseCommands: false),
          room.sendTextEvent('fghij', parseCommands: false),
          room.sendTextEvent('kl', parseCommands: false),
        ]);
        verifyNoOtherSend();
      },
    );

    test(
      'should not send the next part while the previous one is pending',
      () async {
        // Arrange
        final Completer<String?> firstPart = Completer<String?>();
        int sendCount = 0;
        whenSendTextEvent().thenAnswer((_) {
          sendCount++;
          return sendCount == 1 ? firstPart.future : Future.value(r'$event');
        });

        // Act
        final Future<void> sending = interactor.execute(
          room: room,
          text: longText,
        );
        await Future<void>.delayed(Duration.zero);
        final int sendCountWhileFirstPartPending = sendCount;
        firstPart.complete(r'$first');
        await sending;

        // Assert
        expect(sendCountWhileFirstPartPending, equals(1));
        expect(sendCount, equals(3));
      },
    );

    test(
      'should send a second text after every part of a pending long text',
      () async {
        // Arrange
        final Completer<String?> firstPart = Completer<String?>();
        int sendCount = 0;
        whenSendTextEvent().thenAnswer((_) {
          sendCount++;
          return sendCount == 1 ? firstPart.future : Future.value(r'$event');
        });

        // Act
        final Future<void> sendingLongText = interactor.execute(
          room: room,
          text: longText,
        );
        final Future<void> sendingThanks = interactor.execute(
          room: room,
          text: 'Thanks',
        );
        await Future<void>.delayed(Duration.zero);
        firstPart.complete(r'$first');
        await Future.wait([sendingLongText, sendingThanks]);

        // Assert
        verifyInOrder([
          room.sendTextEvent('abcde', parseCommands: false),
          room.sendTextEvent('fghij', parseCommands: false),
          room.sendTextEvent('kl', parseCommands: false),
          room.sendTextEvent('Thank', parseCommands: false),
          room.sendTextEvent('s', parseCommands: false),
        ]);
      },
    );

    test('should attach the reply to the first part only', () async {
      // Arrange
      final MockEvent repliedEvent = MockEvent();

      // Act
      await interactor.execute(
        room: room,
        text: longText,
        inReplyTo: repliedEvent,
      );

      // Assert
      verifyInOrder([
        room.sendTextEvent(
          'abcde',
          inReplyTo: repliedEvent,
          parseCommands: false,
        ),
        room.sendTextEvent('fghij', parseCommands: false),
        room.sendTextEvent('kl', parseCommands: false),
      ]);
    });

    test('should still send the remaining parts when a part throws', () async {
      // Arrange
      whenSendTextEvent().thenAnswer((invocation) async {
        final String part = invocation.positionalArguments.first as String;
        if (part == 'fghij') throw EventTooLarge(60000, 70000);
        return r'$event';
      });

      // Act
      await interactor.execute(room: room, text: longText);

      // Assert
      verifyInOrder([
        room.sendTextEvent('abcde', parseCommands: false),
        room.sendTextEvent('fghij', parseCommands: false),
        room.sendTextEvent('kl', parseCommands: false),
      ]);
    });

    test(
      'should still send the remaining parts when a part fails without throwing',
      () async {
        // Arrange: null means the SDK flagged the part as failed.
        whenSendTextEvent().thenAnswer((invocation) async {
          final String part = invocation.positionalArguments.first as String;
          return part == 'fghij' ? null : r'$event';
        });

        // Act
        await interactor.execute(room: room, text: longText);

        // Assert
        verify(room.sendTextEvent('kl', parseCommands: false)).called(1);
      },
    );

    test('should send the whole text as one edit when editing', () async {
      // Act
      await interactor.execute(
        room: room,
        text: longText,
        editEvent: textEvent(),
      );

      // Assert
      verify(
        room.sendTextEvent(
          longText,
          editEventId: editEventId,
          parseCommands: false,
        ),
      ).called(1);
      verifyNoOtherSend();
    });

    test('should keep the file and its name when editing a caption', () async {
      // Arrange
      final Event image = mediaEvent({
        'msgtype': MessageTypes.Image,
        'body': 'Old caption',
        'format': 'org.matrix.custom.html',
        'formatted_body': '<b>Old caption</b>',
        'filename': 'photo.jpg',
        'url': 'mxc://example.org/photo',
        'info': {'mimetype': 'image/jpeg', 'w': 400, 'h': 300},
        'm.mentions': {},
      });

      // Act
      await interactor.execute(
        room: room,
        text: 'New caption',
        editEvent: image,
      );

      // Assert
      verify(
        room.sendEvent({
          'msgtype': MessageTypes.Image,
          'body': 'New caption',
          'filename': 'photo.jpg',
          'url': 'mxc://example.org/photo',
          'info': {'mimetype': 'image/jpeg', 'w': 400, 'h': 300},
        }, editEventId: editEventId),
      ).called(1);
      verifyNoOtherSend();
    });

    test(
      'should keep the encrypted file and drop the reply relation when editing '
      'a caption',
      () async {
        // Arrange
        final Map<String, Object?> file = {
          'url': 'mxc://example.org/doc',
          'v': 'v2',
        };
        final Event document = mediaEvent({
          'msgtype': MessageTypes.File,
          'body': 'Old caption',
          'filename': 'report.pdf',
          'file': file,
          'm.relates_to': {
            'm.in_reply_to': {'event_id': r'$parent'},
          },
        });

        // Act
        await interactor.execute(
          room: room,
          text: '**New**',
          editEvent: document,
        );

        // Assert
        verify(
          room.sendEvent({
            'msgtype': MessageTypes.File,
            'body': '**New**',
            'format': 'org.matrix.custom.html',
            'formatted_body': '<strong>New</strong>',
            'filename': 'report.pdf',
            'file': file,
          }, editEventId: editEventId),
        ).called(1);
        verifyNoOtherSend();
      },
    );

    test(
      'should keep the body as the file name when the file had no filename',
      () async {
        // Arrange
        final Event video = mediaEvent({
          'msgtype': MessageTypes.Video,
          'body': 'clip.mp4',
          'url': 'mxc://example.org/clip',
        });

        // Act
        await interactor.execute(
          room: room,
          text: 'A caption',
          editEvent: video,
        );

        // Assert
        verify(
          room.sendEvent({
            'msgtype': MessageTypes.Video,
            'body': 'A caption',
            'filename': 'clip.mp4',
            'url': 'mxc://example.org/clip',
          }, editEventId: editEventId),
        ).called(1);
        verifyNoOtherSend();
      },
    );

    test(
      'should let the SDK run a known command without splitting it',
      () async {
        // Arrange
        const String command = '/me $longText';

        // Act
        await interactor.execute(room: room, text: command);

        // Assert
        verify(room.sendTextEvent(command, parseCommands: true)).called(1);
        verifyNoOtherSend();
      },
    );

    test(
      'should split a text starting with an unknown command as plain text',
      () async {
        // Arrange: thirteen characters, leading slash.
        const String text = '/$longText';

        // Act
        await interactor.execute(room: room, text: text);

        // Assert
        verifyInOrder([
          room.sendTextEvent('/abcd', parseCommands: false),
          room.sendTextEvent('efghi', parseCommands: false),
          room.sendTextEvent('jkl', parseCommands: false),
        ]);
        verifyNoOtherSend();
      },
    );

    test(
      'should split a text starting with a double slash as plain text',
      () async {
        // Arrange: pasted code often starts with a comment marker.
        const String text = '//$longText';

        // Act
        await interactor.execute(room: room, text: text);

        // Assert
        verifyInOrder([
          room.sendTextEvent('//abc', parseCommands: false),
          room.sendTextEvent('defgh', parseCommands: false),
          room.sendTextEvent('ijkl', parseCommands: false),
        ]);
        verifyNoOtherSend();
      },
    );

    test(
      'should send an edit verbatim when its text starts with an unknown command',
      () async {
        // Arrange
        const String text = '/foo bar';

        // Act
        await interactor.execute(
          room: room,
          text: text,
          editEvent: textEvent(),
        );

        // Assert
        verify(
          room.sendTextEvent(
            text,
            editEventId: editEventId,
            parseCommands: false,
          ),
        ).called(1);
        verifyNoOtherSend();
      },
    );
  });
}
