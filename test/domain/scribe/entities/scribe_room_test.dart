import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';

void main() {
  bool webOffersScribe(ScribeRoom room) =>
      !room.isEncrypted || (!room.isDirect && room.scribeEnabled);
  bool webHasSetting(ScribeRoom room) =>
      room.isEncrypted && !room.isDirect && !room.isSpace;

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

  test('every room follows Chat web, all 32 combinations', () {
    final rooms = List.generate(
      32,
      (bits) => ScribeRoom(
        isEncrypted: bits & 1 != 0,
        isDirect: bits & 2 != 0,
        scribeEnabled: bits & 4 != 0,
        isSpace: bits & 8 != 0,
        isOwner: bits & 16 != 0,
      ),
    );
    for (final room in rooms) {
      expect(room.offersScribe, webOffersScribe(room), reason: '$room');
      expect(room.hasScribeSetting, webHasSetting(room), reason: '$room');
      expect(
        room.canChangeScribe,
        webHasSetting(room) && room.isOwner,
        reason: '$room',
      );
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
