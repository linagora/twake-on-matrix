import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

import '../../fake_client.dart';

void main() {
  late Room room;

  Event textEvent(String body) => Event(
    content: {'body': body, 'msgtype': 'm.text'},
    type: 'm.room.message',
    eventId: '\$event:example.org',
    senderId: '@example:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
    room: room,
  );

  setUpAll(() async {
    final client = await getClient();
    room = Room(id: '!localpart:server.abc', client: client);
  });

  group('Event.isContains', () {
    test('matches ignoring case', () {
      expect(textEvent('Hello World').isContains('hello'), isTrue);
    });

    test('matches ignoring case for Cyrillic', () {
      expect(textEvent('Привет мир').isContains('привет'), isTrue);
      expect(textEvent('привет мир').isContains('Привет'), isTrue);
    });

    test('matches a term without diacritics against a body with them', () {
      expect(textEvent('Hello Böb').isContains('bob'), isTrue);
      expect(textEvent('Nguyễn Văn A').isContains('nguyen van'), isTrue);
    });

    test('matches a term with diacritics against a body without them', () {
      expect(textEvent('Hello Bob').isContains('Böb'), isTrue);
    });

    test('does not match an unrelated term', () {
      expect(textEvent('Hello Böb').isContains('alice'), isFalse);
    });

    test('matches everything when the term is null or empty', () {
      expect(textEvent('Hello').isContains(null), isTrue);
      expect(textEvent('Hello').isContains(''), isTrue);
    });
  });
}
