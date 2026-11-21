import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/message_link/policy/message_link_policy.dart';

void main() {
  const policy = MessageLinkPolicy();
  const roomId = '!abc:example.org';
  const eventId = r'$evt_1:example.org';

  group('MessageLinkPolicy.build', () {
    test('builds an encoded matrix.to permalink', () {
      expect(
        policy.build(roomId: roomId, eventId: eventId),
        'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org'
        '?via=example.org',
      );
    });

    test('is parsed back to the room and message by the Matrix SDK', () {
      final parts = policy
          .build(roomId: roomId, eventId: eventId)
          .parseIdentifierIntoParts();

      expect(parts?.primaryIdentifier, roomId);
      expect(parts?.secondaryIdentifier, eventId);
    });

    test('names the user server, then the room server, as via', () {
      final link = policy.build(
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
          roomId: '!opaque',
          eventId: eventId,
          userId: '@me:other.org',
        ),
        'https://matrix.to/#/!opaque/%24evt_1%3Aexample.org?via=other.org',
      );
    });
  });

  group('MessageLinkPolicy.matrixToForRoomsLink', () {
    // The links the Twake Chat web app copies, from any host: messageLink()
    // and roomLink() in twake-space-chat src/domain/permalink.ts.
    test('turns a rooms link of a room id into its matrix.to link', () {
      expect(
        policy.matrixToForRoomsLink(
          'https://chat.other.org/rooms/!abc%3Aexample.org'
          '?event=%24evt_1%3Aexample.org',
        ),
        'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org',
      );
      expect(
        policy.matrixToForRoomsLink(
          'https://chat.other.org/rooms/!abc%3Aexample.org',
        ),
        'https://matrix.to/#/!abc%3Aexample.org',
      );
    });

    test('turns the share link of a room, on its alias, into its matrix.to '
        'link', () {
      final link = policy.matrixToForRoomsLink(
        'https://chat.other.org/rooms/%23general%3Aexample.org',
      );

      expect(link, 'https://matrix.to/#/%23general%3Aexample.org');
      final parts = link?.parseIdentifierIntoParts();
      expect(parts?.primaryIdentifier, '#general:example.org');
      expect(parts?.secondaryIdentifier, isNull);
    });

    test('turns a link to a message of an alias into its matrix.to link', () {
      final link = policy.matrixToForRoomsLink(
        'https://chat.other.org/rooms/%23general%3Aexample.org'
        '?event=%24evt_1%3Aexample.org',
      );

      expect(
        link,
        'https://matrix.to/#/%23general%3Aexample.org/%24evt_1%3Aexample.org',
      );
      final parts = link?.parseIdentifierIntoParts();
      expect(parts?.primaryIdentifier, '#general:example.org');
      expect(parts?.secondaryIdentifier, eventId);
    });

    test('needs no knowledge of the room: one the user is not in gets its '
        'matrix.to link too', () {
      // The app then previews the room instead of opening the browser.
      expect(
        policy.matrixToForRoomsLink(
          'https://chat.other.org/rooms/!unknown%3Aexample.org',
        ),
        'https://matrix.to/#/!unknown%3Aexample.org',
      );
      final link = policy.matrixToForRoomsLink(
        'https://chat.other.org/rooms/!unknown%3Aexample.org'
        '?event=%24evt_1%3Aexample.org',
      );
      expect(
        link,
        'https://matrix.to/#/!unknown%3Aexample.org/%24evt_1%3Aexample.org',
      );
      final parts = link?.parseIdentifierIntoParts();
      expect(parts?.primaryIdentifier, '!unknown:example.org');
      expect(parts?.secondaryIdentifier, eventId);
    });

    test('keeps the via servers of a room link', () {
      // A room version 12 id names no server: via is all that routes to it.
      final link = policy.matrixToForRoomsLink(
        'https://chat.other.org/rooms/!abc?via=example.org&via=other.org',
      );

      expect(link, 'https://matrix.to/#/!abc?via=example.org&via=other.org');
      final parts = link?.parseIdentifierIntoParts();
      expect(parts?.primaryIdentifier, '!abc');
      expect(parts?.secondaryIdentifier, isNull);
      expect(parts?.via, {'example.org', 'other.org'});
    });

    test('keeps the via servers of a message link', () {
      final link = policy.matrixToForRoomsLink(
        'https://chat.other.org/rooms/!abc'
        '?event=%24evt_1%3Aexample.org&via=example.org&via=other.org',
      );

      expect(
        link,
        'https://matrix.to/#/!abc/%24evt_1%3Aexample.org'
        '?via=example.org&via=other.org',
      );
      final parts = link?.parseIdentifierIntoParts();
      expect(parts?.primaryIdentifier, '!abc');
      expect(parts?.secondaryIdentifier, eventId);
      expect(parts?.via, {'example.org', 'other.org'});
    });

    test('keeps the via servers of an alias link', () {
      final link = policy.matrixToForRoomsLink(
        'https://chat.other.org/rooms/%23general%3Aexample.org?via=other.org',
      );

      expect(
        link,
        'https://matrix.to/#/%23general%3Aexample.org?via=other.org',
      );
      final parts = link?.parseIdentifierIntoParts();
      expect(parts?.primaryIdentifier, '#general:example.org');
      expect(parts?.via, {'other.org'});
    });

    test('ignores links that are not an https rooms link of a room', () {
      for (final link in [
        'http://chat.other.org/rooms/!abc%3Aexample.org',
        'http://chat.other.org/rooms/%23general%3Aexample.org',
        'https://chat.other.org/rooms/!abc%3Aexample.org/details',
        'https://chat.other.org/rooms/%23general%3Aexample.org/details',
        'https://chat.other.org/embed/rooms/!abc%3Aexample.org',
        'https://chat.other.org/room/!abc%3Aexample.org',
        'https://chat.other.org/room/%23general%3Aexample.org',
        'https://chat.other.org/rooms/abc',
        'https://chat.other.org/rooms/%40someone%3Aexample.org',
        'https://chat.other.org/rooms/',
        'https://chat.other.org/rooms',
      ]) {
        expect(policy.matrixToForRoomsLink(link), isNull, reason: link);
      }
    });

    test('ignores an alias that names no server', () {
      for (final link in [
        'https://chat.other.org/rooms/%23general',
        'https://chat.other.org/rooms/%23general%3A',
        'https://chat.other.org/rooms/%23',
      ]) {
        expect(policy.matrixToForRoomsLink(link), isNull, reason: link);
      }
    });
  });

  group('MessageLinkPolicy with malformed percent-encoding', () {
    test('ignores a rooms link whose path or query does not decode', () {
      for (final link in [
        'https://example.org/%FF',
        'https://example.org/rooms/%FF',
        'https://example.org/rooms/!abc%3Aexample.org?event=%FF',
        'https://example.org/rooms/!abc%3Aexample.org?via=%FF',
      ]) {
        expect(policy.matrixToForRoomsLink(link), isNull, reason: link);
      }
    });
  });
}
