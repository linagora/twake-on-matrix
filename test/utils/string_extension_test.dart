import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[normalizePhoneNumber]', () {
    test('should return phone number without any Hyphens or Parentheses', () {
      const phoneNumber = '(212)555-6789';
      const expectedPhoneNumber = '2125556789';

      final result = phoneNumber.normalizePhoneNumber();

      expect(result, equals(expectedPhoneNumber));
    });

    test('should return phone number without any Spaces or Dashes', () {
      const phoneNumber = '212 555-6789';
      const expectedPhoneNumber = '2125556789';

      final result = phoneNumber.normalizePhoneNumber();

      expect(result, equals(expectedPhoneNumber));
    });

    test('should return phone number without any Plus Sign or Dots', () {
      const phoneNumber = '+1.123.456.7890';
      const expectedPhoneNumber = '11234567890';

      final result = phoneNumber.normalizePhoneNumber();

      expect(result, equals(expectedPhoneNumber));
    });

    test('should return phone number without any Country Code or Extension',
        () {
      const phoneNumber = '+1 (800)-555-1234 ext. 123';
      const expectedPhoneNumber = '18005551234123';

      final result = phoneNumber.normalizePhoneNumber();

      expect(result, equals(expectedPhoneNumber));
    });

    test('should return phone number without any special characters', () {
      const phoneNumber = '+1 (800)-555.1234 ext. 325';
      const expectedPhoneNumber = '18005551234325';

      final result = phoneNumber.normalizePhoneNumber();

      expect(result, equals(expectedPhoneNumber));
    });
  });
}
