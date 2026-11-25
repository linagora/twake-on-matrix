import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

import '../../fake_client.dart';

void main() {
  late Room room;
  const pdf = 'Contributions.pdf';

  Event file(Map<String, Object?> content, {String msgtype = 'm.file'}) =>
      Event(
        content: {
          'msgtype': msgtype,
          'url': 'mxc://example.org/abc',
          ...content,
        },
        type: 'm.room.message',
        eventId: '\$file:example.org',
        senderId: '@alice:example.org',
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
        room: room,
      );

  setUpAll(() async {
    room = Room(id: '!room:example.org', client: await getClient());
  });

  group('Event.fileCaption', () {
    test('is the body of a file sent with a caption', () {
      final event = file({'body': 'Would this do?', 'filename': pdf});

      expect(event.fileCaption, 'Would this do?');
    });

    test('is null when the body is the file name', () {
      expect(file({'body': pdf, 'filename': pdf}).fileCaption, isNull);
    });

    test('is null without a filename field, as Element sends files', () {
      expect(file({'body': pdf}).fileCaption, isNull);
    });

    test('is null for an image, which has its own preview', () {
      final image = file({
        'body': 'Look',
        'filename': 'cat.png',
      }, msgtype: 'm.image');

      expect(image.fileCaption, isNull);
    });

    test('drops the reply fallback of a file sent as a reply', () {
      final event = file({
        'body': '> <@bob:example.org> the report?\n\nHere it is',
        'filename': pdf,
        'm.relates_to': {
          'm.in_reply_to': {'event_id': '\$question:example.org'},
        },
      });

      expect(event.fileCaption, 'Here it is');
    });
  });

  group('Event.chatListFileText', () {
    test('puts a multi-line caption on one line', () {
      final event = file({'body': 'Would this\ndo?', 'filename': pdf});

      expect(event.chatListFileText, 'Would this do?');
    });

    test('is the file name when there is no caption', () {
      expect(file({'body': pdf, 'filename': pdf}).chatListFileText, pdf);
    });
  });
}
