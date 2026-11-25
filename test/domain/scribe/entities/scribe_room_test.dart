import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';

void main() {
  group('ScribeRoom.offersScribe', () {
    test('a clear room offers it, direct or not', () {
      for (final isDirect in [false, true]) {
        expect(
          ScribeRoom(
            isEncrypted: false,
            isDirect: isDirect,
            scribeEnabled: false,
          ).offersScribe,
          isTrue,
        );
      }
    });

    test('an encrypted group offers it only when its owner turned it on', () {
      expect(
        const ScribeRoom(
          isEncrypted: true,
          isDirect: false,
          scribeEnabled: false,
        ).offersScribe,
        isFalse,
      );
      expect(
        const ScribeRoom(
          isEncrypted: true,
          isDirect: false,
          scribeEnabled: true,
        ).offersScribe,
        isTrue,
      );
    });

    test('an encrypted direct room never offers it, even turned on', () {
      expect(
        const ScribeRoom(
          isEncrypted: true,
          isDirect: true,
          scribeEnabled: true,
        ).offersScribe,
        isFalse,
      );
    });
  });

  test('every room follows Chat web (D215), all 32 combinations', () {
    const flags = [false, true];
    for (final isEncrypted in flags) {
      for (final isDirect in flags) {
        for (final scribeEnabled in flags) {
          for (final isSpace in flags) {
            for (final isOwner in flags) {
              final room = ScribeRoom(
                isEncrypted: isEncrypted,
                isDirect: isDirect,
                scribeEnabled: scribeEnabled,
                isSpace: isSpace,
                isOwner: isOwner,
              );
              // twake-space-chat: `offersScribe` (src/domain/room.ts) and
              // `useScribeSection` (src/ui/RoomScribeSection.tsx).
              final offers = !isEncrypted || (!isDirect && scribeEnabled);
              final hasSetting = isEncrypted && !isDirect && !isSpace;
              expect(room.offersScribe, offers, reason: '$room');
              expect(room.hasScribeSetting, hasSetting, reason: '$room');
              expect(
                room.canChangeScribe,
                hasSetting && isOwner,
                reason: '$room',
              );
            }
          }
        }
      }
    }
  });

  group('ScribeRoom setting', () {
    const group = ScribeRoom(
      isEncrypted: true,
      isDirect: false,
      scribeEnabled: false,
    );

    test('an encrypted group has it; the owner alone changes it', () {
      expect(group.hasScribeSetting, isTrue);
      expect(group.canChangeScribe, isFalse);
      expect(group.copyWith(isOwner: true).canChangeScribe, isTrue);
    });

    test('a clear room, a direct chat and a space have none', () {
      for (final room in [
        group.copyWith(isEncrypted: false, isOwner: true),
        group.copyWith(isDirect: true, isOwner: true),
        group.copyWith(isSpace: true, isOwner: true),
      ]) {
        expect(room.hasScribeSetting, isFalse, reason: '$room');
        expect(room.canChangeScribe, isFalse, reason: '$room');
      }
    });
  });
}
