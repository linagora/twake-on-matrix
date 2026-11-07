import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

import '../../fake_client.dart';

/// THR-M-05 (docs/plan/2026-11-06-threads-mobile-spec.md) and the Matrix
/// client-server spec, Threading, "Replies within threads": the
/// m.in_reply_to of a thread reply flagged is_falling_back: true is only a
/// fallback for clients without threads and must not show a quote;
/// is_falling_back defaults to false, so a threaded message can still carry a
/// genuine reply.
void main() {
  late Room room;

  Event message({Map<String, Object?>? relatesTo}) => Event(
    content: {'body': 'Hello', 'msgtype': 'm.text', 'm.relates_to': ?relatesTo},
    type: 'm.room.message',
    eventId: '\$reply:example.org',
    senderId: '@example:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
    room: room,
  );

  Map<String, Object?> threadRelation({bool? isFallingBack}) => {
    'rel_type': 'm.thread',
    'event_id': '\$root:example.org',
    'is_falling_back': ?isFallingBack,
    'm.in_reply_to': {'event_id': '\$last:example.org'},
  };

  setUpAll(() async {
    final client = await getClient();
    room = Room(id: '!localpart:server.abc', client: client);
  });

  group('Event.isReplyEvent', () {
    test('a thread reply whose reply is only the fallback shows no quote', () {
      final event = message(relatesTo: threadRelation(isFallingBack: true));

      expect(event.isReplyEvent(), isFalse);
    });

    test('a genuine reply inside a thread keeps its quote', () {
      final event = message(relatesTo: threadRelation(isFallingBack: false));

      expect(event.isReplyEvent(), isTrue);
    });

    test('a reply inside a thread without is_falling_back keeps its quote', () {
      final event = message(relatesTo: threadRelation());

      expect(event.isReplyEvent(), isTrue);
    });

    test('a plain reply outside a thread shows its quote', () {
      final event = message(
        relatesTo: {
          'm.in_reply_to': {'event_id': '\$quoted:example.org'},
        },
      );

      expect(event.isReplyEvent(), isTrue);
    });

    test('a message without relation is not a reply', () {
      expect(message().isReplyEvent(), isFalse);
    });
  });
}
