import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/message_link/policy/message_link_policy.dart';

void main() {
  const policy = MessageLinkPolicy();
  const roomId = '!abc:example.org';
  const eventId = r'$evt_1:example.org';

  group('MessageLinkPolicy.build with a web origin', () {
    test('matches the link of the web app', () {
      // Same output as messageLink() in twake-space-chat
      // src/domain/permalink.ts (encodeURIComponent of each id).
      expect(
        policy.build(
          webAppOrigin: 'https://chat.example.org',
          roomId: roomId,
          eventId: eventId,
        ),
        'https://chat.example.org/rooms/!abc%3Aexample.org'
        '?event=%24evt_1%3Aexample.org',
      );
    });

    test('decodes back to the same room and message', () {
      final uri = Uri.parse(
        policy.build(
          webAppOrigin: 'https://chat.example.org',
          roomId: roomId,
          eventId: eventId,
        ),
      );

      expect(uri.pathSegments, ['rooms', roomId]);
      expect(uri.queryParameters['event'], eventId);
    });
  });

  group('MessageLinkPolicy.build without a web origin', () {
    test('builds an encoded matrix.to permalink', () {
      expect(
        policy.build(webAppOrigin: null, roomId: roomId, eventId: eventId),
        'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org',
      );
    });

    test('is parsed back to the room and message by the Matrix SDK', () {
      final parts = policy
          .build(webAppOrigin: null, roomId: roomId, eventId: eventId)
          .parseIdentifierIntoParts();

      expect(parts?.primaryIdentifier, roomId);
      expect(parts?.secondaryIdentifier, eventId);
    });
  });

  group('MessageLinkPolicy.matrixToForWebLink', () {
    const origin = 'https://chat.example.org';

    test('turns a web app message link into its matrix.to link', () {
      final webLink = policy.build(
        webAppOrigin: origin,
        roomId: roomId,
        eventId: eventId,
      );

      expect(
        policy.matrixToForWebLink(webLink, webAppOrigin: origin),
        policy.build(webAppOrigin: null, roomId: roomId, eventId: eventId),
      );
    });

    test('turns a web app room link into a matrix.to room link', () {
      expect(
        policy.matrixToForWebLink(
          '$origin/rooms/!abc%3Aexample.org',
          webAppOrigin: origin,
        ),
        'https://matrix.to/#/!abc%3Aexample.org',
      );
    });

    test('ignores links of another origin or another path', () {
      expect(
        policy.matrixToForWebLink(
          'https://other.example.org/rooms/!abc%3Aexample.org',
          webAppOrigin: origin,
        ),
        isNull,
      );
      expect(
        policy.matrixToForWebLink(
          '$origin/rooms/!abc%3Aexample.org/details',
          webAppOrigin: origin,
        ),
        isNull,
      );
      expect(
        policy.matrixToForWebLink('$origin/settings', webAppOrigin: origin),
        isNull,
      );
    });

    test('ignores every link while the web app origin is unknown', () {
      expect(
        policy.matrixToForWebLink(
          '$origin/rooms/!abc%3Aexample.org',
          webAppOrigin: null,
        ),
        isNull,
      );
    });
  });
}
