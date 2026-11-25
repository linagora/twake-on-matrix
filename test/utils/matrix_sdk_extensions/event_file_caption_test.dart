import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

import '../../fake_client.dart';

/// Issue #3263: the chat list shows the caption a file was sent with, not
/// « sent a file ». Per the Matrix spec (v1.10, `m.file`), `body` is a caption
/// only when `filename` is present and differs from it.
/// https://spec.matrix.org/v1.10/client-server-api/#mfile
void main() {
  late Room room;
  final l10n = lookupL10n(const Locale('en'));
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

  group('chat list preview of a file', () {
    test('shows the caption on one line', () async {
      final event = file({'body': 'Would this\ndo?', 'filename': pdf});

      expect(
        await event.calcLocalizedBodyRemoveBreakLine(l10n),
        'Would this do?',
      );
      expect(
        event.calcLocalizedBodyFallbackRemoveBreakLine(l10n),
        'Would this do?',
      );
    });

    test('still says a file was sent when there is no caption', () async {
      final event = file({'body': pdf, 'filename': pdf});

      expect(
        await event.calcLocalizedBodyRemoveBreakLine(l10n),
        contains('sent a file'),
      );
    });
  });
}
