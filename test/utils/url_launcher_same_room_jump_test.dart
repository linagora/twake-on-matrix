import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/url_launcher.dart';

void main() {
  const roomId = '!room:example.org';

  group('jumpsInOpenChat', () {
    test('jumps in place for a message of the chat that is open', () {
      expect(jumpsInOpenChat(openRoomId: roomId, targetRoomId: roomId), isTrue);
    });

    test('navigates for a message of another chat', () {
      expect(
        jumpsInOpenChat(openRoomId: '!other:example.org', targetRoomId: roomId),
        isFalse,
      );
    });

    test('navigates when the link is not tapped inside a chat', () {
      expect(jumpsInOpenChat(openRoomId: null, targetRoomId: roomId), isFalse);
    });
  });
}
