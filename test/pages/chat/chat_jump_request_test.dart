import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/chat.dart';

void main() {
  group('ChatJumpRequest.requestedEventId', () {
    test('is the row id when the asked event has its own row', () {
      const request = ChatJumpRequest(
        eventId: r'$event',
        generation: 1,
        highlight: true,
      );

      expect(request.requestedEventId, r'$event');
    });
  });
}
