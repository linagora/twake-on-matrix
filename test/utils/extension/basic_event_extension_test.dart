import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/extension/basic_event_extension.dart';

void main() {
  group('formatContentForwards', () {
    test('sends a sticker as an image message', () {
      final sticker = BasicEvent(
        type: EventTypes.Sticker,
        content: {
          'body': 'Happy cat',
          'url': 'mxc://example.org/sticker',
          'info': {'mimetype': 'image/png', 'w': 256, 'h': 256},
        },
      );

      expect(sticker.formatContentForwards(), {
        'msgtype': MessageTypes.Image,
        'body': 'Happy cat',
        'url': 'mxc://example.org/sticker',
        'info': {'mimetype': 'image/png', 'w': 256, 'h': 256},
      });
    });

    test('keeps the msgtype of a regular message', () {
      final message = BasicEvent(
        type: EventTypes.Message,
        content: {'msgtype': MessageTypes.Text, 'body': 'Hello'},
      );

      expect(message.formatContentForwards(), {
        'msgtype': MessageTypes.Text,
        'body': 'Hello',
      });
    });

    test('drops the relation without touching the original event', () {
      final reply = BasicEvent(
        type: EventTypes.Message,
        content: {
          'msgtype': MessageTypes.Text,
          'body': 'Hello',
          'm.relates_to': {
            'm.in_reply_to': {'event_id': r'$parent'},
          },
        },
      );

      expect(reply.formatContentForwards(), {
        'msgtype': MessageTypes.Text,
        'body': 'Hello',
      });
      expect(reply.content['m.relates_to'], isNotNull);
    });

    test('sends a sticker reply as an image without the relation', () {
      final stickerReply = BasicEvent(
        type: EventTypes.Sticker,
        content: {
          'body': 'Happy cat',
          'url': 'mxc://example.org/sticker',
          'info': {'mimetype': 'image/png', 'w': 256, 'h': 256},
          'm.relates_to': {
            'm.in_reply_to': {'event_id': r'$parent'},
          },
        },
      );

      expect(stickerReply.formatContentForwards(), {
        'msgtype': MessageTypes.Image,
        'body': 'Happy cat',
        'url': 'mxc://example.org/sticker',
        'info': {'mimetype': 'image/png', 'w': 256, 'h': 256},
      });
      expect(stickerReply.content['m.relates_to'], isNotNull);
      expect(stickerReply.content['msgtype'], isNull);
    });
  });
}
