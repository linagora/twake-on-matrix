import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/url_launcher.dart';

void main() {
  const roomId = '!room:example.org';
  const eventId = r'$event:example.org';

  group('jumpsInOpenChat', () {
    test('jumps in place for a message of the chat that is open', () {
      expect(
        jumpsInOpenChat(
          openRoomId: roomId,
          targetRoomId: roomId,
          eventId: eventId,
        ),
        isTrue,
      );
    });

    test('navigates for a message of another chat', () {
      expect(
        jumpsInOpenChat(
          openRoomId: '!other:example.org',
          targetRoomId: roomId,
          eventId: eventId,
        ),
        isFalse,
      );
    });

    test('navigates for a link to the room without a message', () {
      expect(
        jumpsInOpenChat(
          openRoomId: roomId,
          targetRoomId: roomId,
          eventId: null,
        ),
        isFalse,
      );
    });

    test('navigates when the link is not tapped inside a chat', () {
      expect(
        jumpsInOpenChat(
          openRoomId: null,
          targetRoomId: roomId,
          eventId: eventId,
        ),
        isFalse,
      );
    });
  });
}
