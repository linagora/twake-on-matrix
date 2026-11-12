import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/chat.dart';

void main() {
  group('ChatJumpRequest.requestedEventId', () {
    test('keeps the asked id when the jump targets an album row', () {
      // A link to a hidden album image jumps to its leader's row, but the
      // URL bookkeeping (claim, pending jump, retry) uses the asked id.
      const request = ChatJumpRequest(
        eventId: r'$leader',
        requestedEventId: r'$member',
        generation: 1,
        highlight: true,
      );

      expect(request.eventId, r'$leader');
      expect(request.requestedEventId, r'$member');
    });

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
