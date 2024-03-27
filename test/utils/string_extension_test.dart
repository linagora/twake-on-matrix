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

  group(
      '[isContainsHttpProtocol] TEST\n'
      'GIVEN a string\n'
      'USING isContainsUrl function\n'
      'IF the text contains a URL\n'
      'THEN should return true\n'
      'ELSE should return false\n', () {
    final testMap = <String, bool>{
      'https://www.example.com': true,
      'https://www.example.com/': true,
      'https://www.example.com/watch?v=ohg5sjyrha0': true,
      'https://example.com/test/test-a-link/check/1608?test=1': true,
      'https://www.example.com/watch?v=ohg5sjyrha0&feature=related': true,
      'https://example.com/test/test-a-link/check/1608': true,
      'http://www.example.com': true,
      'http://www.example.com/': true,
      'http://www.example.com/watch?v=ohg5sjyrha0': true,
      'http://example.com/test/test-a-link/check/1608/': true,
      'http://example.com/test/test-a-link/check/1608/?test=1': true,
      'https://example': true,
      'www.example.com': false,
      'www.example.com/': false,
      'www.example.com/watch?v=ohg5sjyrha0': false,
      'example.com': false,
      'example.com/test/test-a-link/check/1608': false,
      'example.com/test/test-a-link/check/1608?test=1': false,
      'example.com/test/test-a-link/check/1608/': false,
      'example.com/test/test-a-link/check/1608/?test=1': false,
      'https:/www.example.com': false,
      'http//www.example.com': false,
      'example.com/test test-a-link/check/1608': false,
      'example.com/test/test-a-link/check/1608?test': false,
      'example.com/test/test-a-link/check/1608/?test==1': false,
      'example.com/test/test-a-link/check/1608/?test=1&': false,
      'hello world': false,
      'hello world.com': false,
      'hello world.com/test': false,
      'hello world.com/test/test-a-link': false,
      'hello world.com/test/test-a-link/check': false,
      'hello world.com/test/test-a-link/check/1608': false,
      'hello world.com/test/test-a-link/check/1608?test': false,
      'hello world.com/test/test-a-link/check/1608/?test==1': false,
      'hello world.com/test/test-a-link/check/1608/?test=1&': false,
      'this is a test string': false,
    };

    for (final entry in testMap.entries) {
      test('Testing: ${entry.key} => Expected: ${entry.value}', () {
        final result = entry.key.isContainsHttpProtocol();
        expect(result, entry.value);
      });
    }
  });

  group(
      '[removeHttpProtocol] TEST\n'
      'GIVEN a string\n'
      'USING removeHttpProtocol function\n'
      'IF the URL starts with http:// or https://\n'
      'THEN should return the URL without the protocol\n'
      'ELSE should return the string unchanged\n', () {
    final testMap = <String, String>{
      'https://www.example.com': 'www.example.com',
      'https://www.example.com/': 'www.example.com/',
      'https://www.example.com/watch?v=ohg5sjyrha0':
          'www.example.com/watch?v=ohg5sjyrha0',
      'https://example.com/test/test-a-link/check/1608?test=1':
          'example.com/test/test-a-link/check/1608?test=1',
      'https://www.example.com/watch?v=ohg5sjyrha0&feature=related':
          'www.example.com/watch?v=ohg5sjyrha0&feature=related',
      'https://example.com/test/test-a-link/check/1608':
          'example.com/test/test-a-link/check/1608',
      'http://www.example.com': 'www.example.com',
      'http://www.example.com/': 'www.example.com/',
      'http://www.example.com/watch?v=ohg5sjyrha0':
          'www.example.com/watch?v=ohg5sjyrha0',
      'http://example.com/test/test-a-link/check/1608/':
          'example.com/test/test-a-link/check/1608/',
      'http://example.com/test/test-a-link/check/1608/?test=1':
          'example.com/test/test-a-link/check/1608/?test=1',
      'https://example': 'example',
      'www.example.com': 'www.example.com',
      'www.example.com/': 'www.example.com/',
      'www.example.com/watch?v=ohg5sjyrha0':
          'www.example.com/watch?v=ohg5sjyrha0',
      'example.com': 'example.com',
      'example.com/test/test-a-link/check/1608':
          'example.com/test/test-a-link/check/1608',
      'example.com/test/test-a-link/check/1608?test=1':
          'example.com/test/test-a-link/check/1608?test=1',
      'example.com/test/test-a-link/check/1608/':
          'example.com/test/test-a-link/check/1608/',
      'example.com/test/test-a-link/check/1608/?test=1':
          'example.com/test/test-a-link/check/1608/?test=1',
      'https:/www.example.com': 'https:/www.example.com',
      'http//www.example.com': 'http//www.example.com',
      'example.com/test test-a-link/check/1608':
          'example.com/test test-a-link/check/1608',
      'example.com/test/test-a-link/check/1608?test':
          'example.com/test/test-a-link/check/1608?test',
      'example.com/test/test-a-link/check/1608/?test==1':
          'example.com/test/test-a-link/check/1608/?test==1',
      'example.com/test/test-a-link/check/1608/?test=1&':
          'example.com/test/test-a-link/check/1608/?test=1&',
      'hello world': 'hello world',
      'hello world.com': 'hello world.com',
      'hello world.com/test': 'hello world.com/test',
      'hello world.com/test/test-a-link': 'hello world.com/test/test-a-link',
      'hello world.com/test/test-a-link/check':
          'hello world.com/test/test-a-link/check',
      'hello world.com/test/test-a-link/check/1608':
          'hello world.com/test/test-a-link/check/1608',
      'hello world.com/test/test-a-link/check/1608?test':
          'hello world.com/test/test-a-link/check/1608?test',
      'hello world.com/test/test-a-link/check/1608/?test==1':
          'hello world.com/test/test-a-link/check/1608/?test==1',
      'hello world.com/test/test-a-link/check/1608/?test=1&':
          'hello world.com/test/test-a-link/check/1608/?test=1&',
      'this is a test string': 'this is a test string',
    };

    for (final entry in testMap.entries) {
      test('Testing: ${entry.key} => Expected: ${entry.value}', () {
        final result = entry.key.removeHttpProtocol();
        expect(result, entry.value);
      });
    }
  });
}
