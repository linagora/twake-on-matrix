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

  Event captionEdit(String caption, {bool outerFilename = true}) => file({
    'body': '* $caption',
    if (outerFilename) 'filename': pdf,
    'm.new_content': {'msgtype': 'm.file', 'body': caption, 'filename': pdf},
    'm.relates_to': {'rel_type': 'm.replace', 'event_id': '\$file:example.org'},
  });

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

    test('is the file name for a reply whose body is only the fallback', () {
      final event = file({
        'body': '> <@bob:example.org> the report?',
        'filename': pdf,
        'm.relates_to': {
          'm.in_reply_to': {'event_id': '\$question:example.org'},
        },
      });

      expect(event.chatListFileText, pdf);
    });

    test('is the new caption of a caption edit', () {
      expect(captionEdit('new caption').chatListFileText, 'new caption');
    });

    test('is the file name when an edit removes the caption', () {
      expect(captionEdit('').chatListFileText, pdf);
    });

    test('is the new caption of an edit without a file name outside', () {
      final edit = captionEdit('new caption', outerFilename: false);

      expect(edit.chatListFileText, 'new caption');
    });

    test('is the file name of an edit that removes the caption', () {
      expect(captionEdit('', outerFilename: false).chatListFileText, pdf);
    });
  });
}
