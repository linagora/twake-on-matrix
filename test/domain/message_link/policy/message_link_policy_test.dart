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
        'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org'
        '?via=example.org',
      );
    });

    test('is parsed back to the room and message by the Matrix SDK', () {
      final parts = policy
          .build(webAppOrigin: null, roomId: roomId, eventId: eventId)
          .parseIdentifierIntoParts();

      expect(parts?.primaryIdentifier, roomId);
      expect(parts?.secondaryIdentifier, eventId);
    });

    test('names the user server, then the room server, as via', () {
      final link = policy.build(
        webAppOrigin: null,
        roomId: roomId,
        eventId: eventId,
        userId: '@me:other.org',
      );

      expect(
        link,
        'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org'
        '?via=other.org&via=example.org',
      );
      final parts = link.parseIdentifierIntoParts();
      expect(parts?.primaryIdentifier, roomId);
      expect(parts?.secondaryIdentifier, eventId);
      expect(parts?.via, {'other.org', 'example.org'});
    });

    test('names a server once when room and user share it', () {
      expect(
        policy.build(
          webAppOrigin: null,
          roomId: roomId,
          eventId: eventId,
          userId: '@me:example.org',
        ),
        endsWith('?via=example.org'),
      );
    });

    test('names only the user server for a room id without a server', () {
      // Room version 12 ids carry no server name.
      expect(
        policy.build(
          webAppOrigin: null,
          roomId: '!opaque',
          eventId: eventId,
          userId: '@me:other.org',
        ),
        'https://matrix.to/#/!opaque/%24evt_1%3Aexample.org?via=other.org',
      );
    });

    test('keeps the web app link free of via', () {
      expect(
        policy.build(
          webAppOrigin: 'https://chat.example.org',
          roomId: roomId,
          eventId: eventId,
          userId: '@me:other.org',
        ),
        isNot(contains('via=')),
      );
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
        'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org',
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

  group('MessageLinkPolicy.matrixToForRoomsLink', () {
    bool known(String id) => id == roomId;

    test('turns a rooms link of a known room into its matrix.to link', () {
      // A Twake web app whose homeserver does not name it in `web_url`.
      expect(
        policy.matrixToForRoomsLink(
          'https://chat.other.org/rooms/!abc%3Aexample.org'
          '?event=%24evt_1%3Aexample.org',
          isKnownRoom: known,
        ),
        'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org',
      );
      expect(
        policy.matrixToForRoomsLink(
          'https://chat.other.org/rooms/!abc%3Aexample.org',
          isKnownRoom: known,
        ),
        'https://matrix.to/#/!abc%3Aexample.org',
      );
    });

    test('ignores a room the user does not know', () {
      expect(
        policy.matrixToForRoomsLink(
          'https://chat.other.org/rooms/!unknown%3Aexample.org',
          isKnownRoom: known,
        ),
        isNull,
      );
    });

    test('ignores links that are not an https rooms link of a room id', () {
      for (final link in [
        'http://chat.other.org/rooms/!abc%3Aexample.org',
        'https://chat.other.org/rooms/!abc%3Aexample.org/details',
        'https://chat.other.org/room/!abc%3Aexample.org',
        'https://chat.other.org/rooms/abc',
        'https://chat.other.org/rooms/',
      ]) {
        expect(
          policy.matrixToForRoomsLink(link, isKnownRoom: (_) => true),
          isNull,
          reason: link,
        );
      }
    });
  });

  group('MessageLinkPolicy with malformed percent-encoding', () {
    test('ignores a rooms link whose path or query does not decode', () {
      for (final link in [
        'https://example.org/%FF',
        'https://example.org/rooms/%FF',
        'https://example.org/rooms/!abc%3Aexample.org?event=%FF',
      ]) {
        expect(
          policy.matrixToForRoomsLink(link, isKnownRoom: (_) => true),
          isNull,
          reason: link,
        );
      }
    });

    test('ignores a web app link whose path or query does not decode', () {
      const origin = 'https://chat.example.org';
      for (final link in [
        '$origin/%FF',
        '$origin/rooms/!abc%3Aexample.org?event=%FF',
      ]) {
        expect(
          policy.matrixToForWebLink(link, webAppOrigin: origin),
          isNull,
          reason: link,
        );
      }
    });
  });
}
