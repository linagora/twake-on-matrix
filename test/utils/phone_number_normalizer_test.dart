import 'package:fluffychat/utils/phone_number_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryNormalizePhoneNumberToE164', () {
    // --- Local numbers (require country context) ---

    test('normalises local FR number to E.164', () {
      expect(
        tryNormalizePhoneNumberToE164('0612345678', 'FR'),
        equals('+33612345678'),
      );
    });

    test('normalises local FR number with spaces to E.164', () {
      expect(
        tryNormalizePhoneNumberToE164('06 12 34 56 78', 'FR'),
        equals('+33612345678'),
      );
    });

    test('normalises local US number to E.164', () {
      expect(
        tryNormalizePhoneNumberToE164('2125556789', 'US'),
        equals('+12125556789'),
      );
    });

    // --- "00" international prefix ---

    test('normalises "00" prefix to E.164', () {
      expect(
        tryNormalizePhoneNumberToE164('0033612345678', 'FR'),
        equals('+33612345678'),
      );
    });

    test('normalises "00" prefix with spaces to E.164', () {
      expect(
        tryNormalizePhoneNumberToE164('0033 6 12 34 56 78', 'FR'),
        equals('+33612345678'),
      );
    });

    // --- "(0)" trunk prefix in display format ---

    test('normalises "+33 (0) 6..." display format to E.164', () {
      expect(
        tryNormalizePhoneNumberToE164('+33 (0) 6 12 34 56 78', 'FR'),
        equals('+33612345678'),
      );
    });

    test('normalises compact "+33(0)6..." to E.164', () {
      expect(
        tryNormalizePhoneNumberToE164('+33(0)612345678', 'FR'),
        equals('+33612345678'),
      );
    });

    // --- Already correct E.164 formats ---

    test('returns E.164 unchanged for already normalised number', () {
      expect(
        tryNormalizePhoneNumberToE164('+33612345678', 'FR'),
        equals('+33612345678'),
      );
    });

    test('returns E.164 with formatting stripped', () {
      expect(
        tryNormalizePhoneNumberToE164('+33 6 12 34 56 78', 'FR'),
        equals('+33612345678'),
      );
    });

    test('accepts lowercase ISO country code', () {
      expect(
        tryNormalizePhoneNumberToE164('0612345678', 'fr'),
        equals('+33612345678'),
      );
    });

    // --- Invalid / unparseable inputs ---

    test('returns null for a non-numeric string', () {
      expect(tryNormalizePhoneNumberToE164('not-a-number', 'FR'), isNull);
    });

    test('returns null for a number too short to be valid', () {
      expect(tryNormalizePhoneNumberToE164('123', 'FR'), isNull);
    });

    test('returns null for an unknown country code', () {
      expect(tryNormalizePhoneNumberToE164('0612345678', 'XX'), isNull);
    });

    test('returns null for an empty string', () {
      expect(tryNormalizePhoneNumberToE164('', 'FR'), isNull);
    });

    // --- Without callerIsoCode ---

    test(
      'without callerIsoCode: resolves an E.164 number with explicit "+"',
      () {
        expect(
          tryNormalizePhoneNumberToE164('+33612345678', null),
          equals('+33612345678'),
        );
      },
    );

    test(
      'without callerIsoCode: returns null for a local number without "+"',
      () {
        expect(tryNormalizePhoneNumberToE164('0612345678', null), isNull);
      },
    );

    test('without callerIsoCode: returns null for an invalid number', () {
      expect(tryNormalizePhoneNumberToE164('not-a-number', null), isNull);
    });
  });
}
