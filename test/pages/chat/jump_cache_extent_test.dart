import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/jump_cache_extent.dart';

void main() {
  group('JumpCacheExtent', () {
    test('a jump alone restores the extent it found', () {
      final extent = JumpCacheExtent();

      extent.startJump();
      extent.raiseForJump();
      expect(extent.value, JumpCacheExtent.mountExtent);

      expect(extent.endJump(isLatest: true), isTrue);
      expect(extent.value, isNull);
    });

    test('an unread opening alone restores the extent it found', () {
      final extent = JumpCacheExtent();

      extent.startUnreadOpening();
      expect(extent.value, JumpCacheExtent.mountExtent);

      expect(extent.endUnreadOpening(jumpInFlight: false), isTrue);
      expect(extent.value, isNull);
    });

    test('a jump that starts before the unread opening and ends first', () {
      final extent = JumpCacheExtent();

      extent.startJump();
      extent.raiseForJump();
      extent.startUnreadOpening();
      extent.endJump(isLatest: true);
      extent.endUnreadOpening(jumpInFlight: false);

      expect(extent.value, isNull);
    });

    test('a jump that starts during the unread opening and ends last', () {
      final extent = JumpCacheExtent();

      extent.startUnreadOpening();
      extent.startJump();
      extent.raiseForJump();
      extent.endUnreadOpening(jumpInFlight: true);
      extent.endJump(isLatest: true);

      expect(extent.value, isNull);
    });

    test('a superseded jump leaves the restore to the latest one', () {
      final extent = JumpCacheExtent();

      extent.startJump();
      extent.raiseForJump();
      extent.startJump();
      expect(extent.endJump(isLatest: false), isFalse);
      expect(extent.value, JumpCacheExtent.mountExtent);

      extent.endJump(isLatest: true);
      expect(extent.value, isNull);
    });
  });
}
