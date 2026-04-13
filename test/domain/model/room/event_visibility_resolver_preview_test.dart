import 'package:fluffychat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';

import 'room_extension_test.mocks.dart';

void main() {
  late MockRoom room;

  setUp(() {
    room = MockRoom();
    when(room.id).thenReturn('!test:example.com');
  });

  Event redactionStub({required String eventId}) => Event(
    type: EventTypes.Redaction,
    content: {},
    eventId: eventId,
    senderId: '@alice:example.com',
    originServerTs: DateTime.utc(2024, 6, 1),
    room: room,
  );

  group('EventVisibilityResolver.isEligibleForChatListPreview', () {
    test(
      'message without edit relationship is eligible when not redacted',
      () async {
        final message = Event(
          type: EventTypes.Message,
          content: {'msgtype': 'm.text', 'body': 'hello'},
          eventId: '\$msg',
          senderId: '@alice:example.com',
          originServerTs: DateTime.utc(2024, 6, 2),
          room: room,
        );
        expect(
          await EventVisibilityResolver.isEligibleForChatListPreview(
            room,
            message,
          ),
          isTrue,
        );
      },
    );

    test('redacted message is not eligible', () async {
      final message = Event(
        type: EventTypes.Message,
        content: {'msgtype': 'm.text', 'body': 'gone'},
        eventId: '\$msg',
        senderId: '@alice:example.com',
        originServerTs: DateTime.utc(2024, 6, 2),
        room: room,
      );
      message.setRedactionEvent(redactionStub(eventId: '\$red'));
      expect(
        await EventVisibilityResolver.isEligibleForChatListPreview(
          room,
          message,
        ),
        isFalse,
      );
    });

    test('edit is not eligible when replaced message is redacted', () async {
      const originalId = '\$original';
      final original = Event(
        type: EventTypes.Message,
        content: {'msgtype': 'm.text', 'body': 'first'},
        eventId: originalId,
        senderId: '@alice:example.com',
        originServerTs: DateTime.utc(2024, 6, 1),
        room: room,
      );
      original.setRedactionEvent(redactionStub(eventId: '\$red1'));
      when(room.getEventById(originalId)).thenAnswer((_) async => original);

      final edit = Event(
        type: EventTypes.Message,
        content: {
          'msgtype': 'm.text',
          'body': '* edited',
          'm.new_content': {'msgtype': 'm.text', 'body': 'edited'},
          'm.relates_to': {
            'rel_type': RelationshipTypes.edit,
            'event_id': originalId,
          },
        },
        eventId: '\$edit',
        senderId: '@alice:example.com',
        originServerTs: DateTime.utc(2024, 6, 2),
        room: room,
      );

      expect(
        await EventVisibilityResolver.isEligibleForChatListPreview(room, edit),
        isFalse,
      );
    });

    test('edit stays eligible when replaced message is not redacted', () async {
      const originalId = '\$original';
      final original = Event(
        type: EventTypes.Message,
        content: {'msgtype': 'm.text', 'body': 'first'},
        eventId: originalId,
        senderId: '@alice:example.com',
        originServerTs: DateTime.utc(2024, 6, 1),
        room: room,
      );
      when(room.getEventById(originalId)).thenAnswer((_) async => original);

      final edit = Event(
        type: EventTypes.Message,
        content: {
          'msgtype': 'm.text',
          'body': '* edited',
          'm.new_content': {'msgtype': 'm.text', 'body': 'edited'},
          'm.relates_to': {
            'rel_type': RelationshipTypes.edit,
            'event_id': originalId,
          },
        },
        eventId: '\$edit',
        senderId: '@alice:example.com',
        originServerTs: DateTime.utc(2024, 6, 2),
        room: room,
      );

      expect(
        await EventVisibilityResolver.isEligibleForChatListPreview(room, edit),
        isTrue,
      );
    });

    test(
      'second edit is not eligible when root of chain is redacted',
      () async {
        const idA = '\$a';
        const idB = '\$b';
        final a = Event(
          type: EventTypes.Message,
          content: {'msgtype': 'm.text', 'body': 'root'},
          eventId: idA,
          senderId: '@alice:example.com',
          originServerTs: DateTime.utc(2024, 6, 1),
          room: room,
        );
        a.setRedactionEvent(redactionStub(eventId: '\$reda'));

        final b = Event(
          type: EventTypes.Message,
          content: {
            'msgtype': 'm.text',
            'body': '* b',
            'm.new_content': {'msgtype': 'm.text', 'body': 'b'},
            'm.relates_to': {
              'rel_type': RelationshipTypes.edit,
              'event_id': idA,
            },
          },
          eventId: idB,
          senderId: '@alice:example.com',
          originServerTs: DateTime.utc(2024, 6, 2),
          room: room,
        );

        final c = Event(
          type: EventTypes.Message,
          content: {
            'msgtype': 'm.text',
            'body': '* c',
            'm.new_content': {'msgtype': 'm.text', 'body': 'c'},
            'm.relates_to': {
              'rel_type': RelationshipTypes.edit,
              'event_id': idB,
            },
          },
          eventId: '\$c',
          senderId: '@alice:example.com',
          originServerTs: DateTime.utc(2024, 6, 3),
          room: room,
        );

        when(room.getEventById(idA)).thenAnswer((_) async => a);
        when(room.getEventById(idB)).thenAnswer((_) async => b);

        expect(
          await EventVisibilityResolver.isEligibleForChatListPreview(room, c),
          isFalse,
        );
      },
    );
  });
}
