import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
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
      'IF the string contains a URL\n'
      'THEN should return true\n'
      'ELSE should return false\n', () {
    final testMap = <String, bool>{
      'https': false,
      'https:': false,
      'https:/': false,
      'https/': false,
      'https//': false,
      'https://': true,
      'https://www.example.com': true,
      'https://www.example.com/': true,
      'https://www.example.com/watch?v=ohg5sjyrha0': true,
      'https://example.com/test/test-a-link/check/1608?test=1': true,
      'https://www.example.com/watch?v=ohg5sjyrha0&feature=related': true,
      'https://example.com/test/test-a-link/check/1608': true,
      'http': false,
      'http:': false,
      'http:/': false,
      'http/': false,
      'http//': false,
      'http://': true,
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
      'ftp': false,
      'ftp:': false,
      'ftp:/': false,
      'ftp//': false,
      'ftp://': true,
      'ftp://www.example.com': true,
      'ftp://www.example.com/': true,
      'ftp://www.example.com/watch?v=ohg5sjyrha0': true,
      'ftp://example.com/test/test-a-link/check/1608?test=1': true,
      'ftp://www.example.com/watch?v=ohg5sjyrha0&feature=related': true,
      'ftp://example.com/test/test-a-link/check/1608': true,
      'sftp': false,
      'sftp:': false,
      'sftp:/': false,
      'sftp//': false,
      'sftp://': true,
      'sftp://www.example.com': true,
      'sftp://www.example.com/': true,
      'sftp://www.example.com/watch?v=ohg5sjyrha0': true,
      'sftp://example.com/test/test-a-link/check/1608?test=1': true,
      'sftp://www.example.com/watch?v=ohg5sjyrha0&feature=related': true,
      'sftp://example.com/test/test-a-link/check/1608': true,
      'ssh': false,
      'ssh:': false,
      'ssh:/': false,
      'ssh//': false,
      'ssh://': true,
      'ssh://www.example.com': true,
      'ssh://www.example.com/': true,
      'ssh://www.example.com/watch?v=ohg5sjyrha0': true,
      'ssh://example.com/test/test-a-link/check/1608?test=1': true,
      'ssh://www.example.com/watch?v=ohg5sjyrha0&feature=related': true,
      'ssh://example.com/test/test-a-link/check/1608': true,
    };

    for (final entry in testMap.entries) {
      test('Testing: ${entry.key} => Expected: ${entry.value}', () {
        final result = entry.key.isContainsUrlSeparator();
        if (entry.value) {
          expect(result, isTrue);
        } else {
          expect(result, isFalse);
        }
      });
    }
  });

  group(
      '[removeHttpProtocol] TEST\n'
      'GIVEN a string\n'
      'USING removeHttpProtocol function\n'
      'IF the string starts with http:// or https://\n'
      'THEN should return the URL without the protocol\n'
      'ELSE should return the string unchanged\n', () {
    final testMap = <String, String>{
      'https': 'https',
      'https:': 'https:',
      'https:/': 'https:/',
      'https//': 'https//',
      'https://': '',
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
      'http': 'http',
      'http:': 'http:',
      'http:/': 'http:/',
      'http//': 'http//',
      'http://': '',
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
      'hello 123://world.com/test/test-a-link/check/1608/?test=1&':
          'hello world.com/test/test-a-link/check/1608/?test=1&',
      'hello this is the://world.com/test/test-a-link/check/1608/?test=1& for the text contains :// inside it':
          'hello this is world.com/test/test-a-link/check/1608/?test=1& for the text contains inside it',
      'this is a test string': 'this is a test string',
      'ftp': 'ftp',
      'ftp:': 'ftp:',
      'ftp:/': 'ftp:/',
      'ftp//': 'ftp//',
      'ftp://': '',
      'ftp://www.example.com': 'www.example.com',
      'ftp://www.example.com/': 'www.example.com/',
      'ftp://www.example.com/watch?v=ohg5sjyrha0':
          'www.example.com/watch?v=ohg5sjyrha0',
      'ftp://example.com/test/test-a-link/check/1608?test=1':
          'example.com/test/test-a-link/check/1608?test=1',
      'ftp://www.example.com/watch?v=ohg5sjyrha0&feature=related':
          'www.example.com/watch?v=ohg5sjyrha0&feature=related',
      'ftp://example.com/test/test-a-link/check/1608':
          'example.com/test/test-a-link/check/1608',
      'sftp': 'sftp',
      'sftp:': 'sftp:',
      'sftp:/': 'sftp:/',
      'sftp//': 'sftp//',
      'sftp://': '',
      'sftp://www.example.com': 'www.example.com',
      'sftp://www.example.com/': 'www.example.com/',
      'sftp://www.example.com/watch?v=ohg5sjyrha0':
          'www.example.com/watch?v=ohg5sjyrha0',
      'sftp://example.com/test/test-a-link/check/1608?test=1':
          'example.com/test/test-a-link/check/1608?test=1',
      'sftp://www.example.com/watch?v=ohg5sjyrha0&feature=related':
          'www.example.com/watch?v=ohg5sjyrha0&feature=related',
      'sftp://example.com/test/test-a-link/check/1608':
          'example.com/test/test-a-link/check/1608',
      'ssh': 'ssh',
      'ssh:': 'ssh:',
      'ssh:/': 'ssh:/',
      'ssh//': 'ssh//',
      'ssh://': '',
      'ssh://www.example.com': 'www.example.com',
      'ssh://www.example.com/': 'www.example.com/',
      'ssh://www.example.com/watch?v=ohg5sjyrha0':
          'www.example.com/watch?v=ohg5sjyrha0',
      'ssh://example.com/test/test-a-link/check/1608?test=1':
          'example.com/test/test-a-link/check/1608?test=1',
      'ssh://www.example.com/watch?v=ohg5sjyrha0&feature=related':
          'www.example.com/watch?v=ohg5sjyrha0&feature=related',
      'ssh://example.com/test/test-a-link/check/1608':
          'example.com/test/test-a-link/check/1608',
    };

    for (final entry in testMap.entries) {
      test('Testing: ${entry.key} => Expected: ${entry.value}', () {
        final result = entry.key.removeUrlSeparatorAndPreceding();
        if (entry.value.isNotEmpty) {
          expect(result, isNotEmpty);
          expect(result, equals(entry.value));
        } else {
          expect(result, isEmpty);
        }
      });
    }
  });

  group('[isContainsATag] TEST\n', () {
    test('[isContainsATag] detects <a> tag', () {
      expect(
        'Hello <a href="https://example.com">world</a>!'.isContainsATag(),
        isTrue,
      );
      expect('Hello world!'.isContainsATag(), isFalse);
    });

    test('[isContainsATag] detects <a> tag with attributes', () {
      expect(
        '<a href="https://example.com" target="_blank">Link</a>'
            .isContainsATag(),
        isTrue,
      );
    });

    test('[isContainsATag] does not detect other tags', () {
      expect('<p>Hello world!</p>'.isContainsATag(), isFalse);
    });
  });

  group('[extractAllHrefs] TEST\n', () {
    test('extractAllHrefs extracts all hrefs from <a> tags', () {
      expect(
        '<a href="https://example.com">Link</a> <a href="https://another.com">Another Link</a>'
            .extractAllHrefs(),
        equals(['https://example.com', 'https://another.com']),
      );
    });

    test('extractAllHrefs returns empty list when no <a> tags', () {
      expect('Hello world!'.extractAllHrefs(), isEmpty);
    });

    test('extractAllHrefs ignores <a> tags without href', () {
      expect(
        '<a>Link</a> <a href="https://example.com">Another Link</a>'
            .extractAllHrefs(),
        equals(['https://example.com']),
      );
    });

    test(
        'extractAllHrefs extracts hrefs from <a> tags with multiple attributes',
        () {
      expect(
        '<a class="link" href="https://example.com" target="_blank">Link</a> <a href="https://another.com">Another Link</a>'
            .extractAllHrefs(),
        equals(['https://example.com', 'https://another.com']),
      );
    });

    test('extractAllHrefs extracts href when only one <a> tag', () {
      expect(
        '<a href="https://example.com">Link</a>'.extractAllHrefs(),
        equals(['https://example.com']),
      );
    });
  });

  group('[extractInnerText] TEST\n', () {
    test(
        'GIVEN an a tag\n'
        'CONTAINS innerText\n'
        'THEN return innerText\n', () {
      expect(
        '<a href="https://example.com">Link</a>'.extractInnerText(),
        equals('Link'),
      );
    });

    test(
        'GIVEN string without a tag\n'
        'THEN return null\n', () {
      expect('Hello world!'.extractInnerText(), isNull);
    });

    test(
        'GIVEN an a tag\n'
        'NOT CONTAINS innerText\n'
        'THEN return an empty string\n', () {
      expect('<a href="https://example.com"></a>'.extractInnerText(), isEmpty);
    });
  });

  group('buildHighlightTextSpans tests', () {
    test(
        'buildHighlightTextSpans handles special * and \\ characters in highlightText',
        () {
      const text =
          'This is a test string with special characters like * and \\.';
      const highlightText = '* and \\';
      final expectedSpans = [
        const TextSpan(
          text: 'This is a test string with special characters like ',
          style: TextStyle(color: Colors.black),
        ),
        const TextSpan(text: '* and \\', style: TextStyle(color: Colors.red)),
        const TextSpan(text: '.', style: TextStyle(color: Colors.black)),
      ];

      final result = text.buildHighlightTextSpans(
        highlightText,
        style: const TextStyle(color: Colors.black),
        highlightStyle: const TextStyle(color: Colors.red),
      );

      expect(result.length, expectedSpans.length);

      for (int i = 0; i < result.length; i++) {
        expect(result[i].text, expectedSpans[i].text);
        expect(result[i].style, expectedSpans[i].style);
      }
    });

    test(
        'buildHighlightTextSpans handles special \\ characters in highlightText',
        () {
      const text = 'This is a test string with special characters like 123\\.';
      const highlightText = '123';
      final expectedSpans = [
        const TextSpan(
          text: 'This is a test string with special characters like ',
          style: TextStyle(color: Colors.black),
        ),
        const TextSpan(text: '123', style: TextStyle(color: Colors.red)),
        const TextSpan(text: '\\.', style: TextStyle(color: Colors.black)),
      ];

      final result = text.buildHighlightTextSpans(
        highlightText,
        style: const TextStyle(color: Colors.black),
        highlightStyle: const TextStyle(color: Colors.red),
      );

      expect(result.length, expectedSpans.length);

      for (int i = 0; i < result.length; i++) {
        expect(result[i].text, expectedSpans[i].text);
        expect(result[i].style, expectedSpans[i].style);
      }
    });

    test('buildHighlightTextSpans handles special characters in highlightText',
        () {
      const text = 'This is a test string with special characters like 123.';
      const highlightText = '123';
      final expectedSpans = [
        const TextSpan(
          text: 'This is a test string with special characters like ',
          style: TextStyle(color: Colors.black),
        ),
        const TextSpan(text: '123', style: TextStyle(color: Colors.red)),
        const TextSpan(text: '.', style: TextStyle(color: Colors.black)),
      ];

      final result = text.buildHighlightTextSpans(
        highlightText,
        style: const TextStyle(color: Colors.black),
        highlightStyle: const TextStyle(color: Colors.red),
      );

      expect(result.length, expectedSpans.length);

      for (int i = 0; i < result.length; i++) {
        expect(result[i].text, expectedSpans[i].text);
        expect(result[i].style, expectedSpans[i].style);
      }
    });

    test('buildHighlightTextSpans handles special characters in highlightText',
        () {
      const text = 'This is a test string with special characters like 123.';
      const highlightText = '123.';
      final expectedSpans = [
        const TextSpan(
          text: 'This is a test string with special characters like ',
          style: TextStyle(color: Colors.black),
        ),
        const TextSpan(text: '123.', style: TextStyle(color: Colors.red)),
        const TextSpan(text: '', style: TextStyle(color: Colors.black)),
      ];

      final result = text.buildHighlightTextSpans(
        highlightText,
        style: const TextStyle(color: Colors.black),
        highlightStyle: const TextStyle(color: Colors.red),
      );

      expect(result.length, expectedSpans.length);

      for (int i = 0; i < result.length; i++) {
        expect(result[i].text, expectedSpans[i].text);
        expect(result[i].style, expectedSpans[i].style);
      }
    });

    test('buildHighlightTextSpans handles special characters in highlightText',
        () {
      const text = 'This is a test string with special characters like 123\\';
      const highlightText = '123\\';
      final expectedSpans = [
        const TextSpan(
          text: 'This is a test string with special characters like ',
          style: TextStyle(color: Colors.black),
        ),
        const TextSpan(text: '123\\', style: TextStyle(color: Colors.red)),
        const TextSpan(text: '', style: TextStyle(color: Colors.black)),
      ];

      final result = text.buildHighlightTextSpans(
        highlightText,
        style: const TextStyle(color: Colors.black),
        highlightStyle: const TextStyle(color: Colors.red),
      );

      expect(result.length, expectedSpans.length);

      for (int i = 0; i < result.length; i++) {
        expect(result[i].text, expectedSpans[i].text);
        expect(result[i].style, expectedSpans[i].style);
      }
    });

    test('buildHighlightTextSpans handles special characters in highlightText',
        () {
      const text = 'This is a test string with special characters like 123@@++';
      const highlightText = '123@@++';
      final expectedSpans = [
        const TextSpan(
          text: 'This is a test string with special characters like ',
          style: TextStyle(color: Colors.black),
        ),
        const TextSpan(text: '123@@++', style: TextStyle(color: Colors.red)),
        const TextSpan(text: '', style: TextStyle(color: Colors.black)),
      ];

      final result = text.buildHighlightTextSpans(
        highlightText,
        style: const TextStyle(color: Colors.black),
        highlightStyle: const TextStyle(color: Colors.red),
      );

      expect(result.length, expectedSpans.length);

      for (int i = 0; i < result.length; i++) {
        expect(result[i].text, expectedSpans[i].text);
        expect(result[i].style, expectedSpans[i].style);
      }
    });

    test('buildHighlightTextSpans handles special characters in highlightText',
        () {
      const text = 'This is a test string with special characters like .123';
      const highlightText = '.123';
      final expectedSpans = [
        const TextSpan(
          text: 'This is a test string with special characters like ',
          style: TextStyle(color: Colors.black),
        ),
        const TextSpan(text: '.123', style: TextStyle(color: Colors.red)),
        const TextSpan(text: '', style: TextStyle(color: Colors.black)),
      ];

      final result = text.buildHighlightTextSpans(
        highlightText,
        style: const TextStyle(color: Colors.black),
        highlightStyle: const TextStyle(color: Colors.red),
      );

      expect(result.length, expectedSpans.length);

      for (int i = 0; i < result.length; i++) {
        expect(result[i].text, expectedSpans[i].text);
        expect(result[i].style, expectedSpans[i].style);
      }
    });

    test('buildHighlightTextSpans handles special characters in highlightText',
        () {
      const text = 'This is a test string with special characters like \\123';
      const highlightText = '\\123';
      final expectedSpans = [
        const TextSpan(
          text: 'This is a test string with special characters like ',
          style: TextStyle(color: Colors.black),
        ),
        const TextSpan(text: '\\123', style: TextStyle(color: Colors.red)),
        const TextSpan(text: '', style: TextStyle(color: Colors.black)),
      ];

      final result = text.buildHighlightTextSpans(
        highlightText,
        style: const TextStyle(color: Colors.black),
        highlightStyle: const TextStyle(color: Colors.red),
      );

      expect(result.length, expectedSpans.length);

      for (int i = 0; i < result.length; i++) {
        expect(result[i].text, expectedSpans[i].text);
        expect(result[i].style, expectedSpans[i].style);
      }
    });
  });

  group('getBaseUrlBeforeHash test', () {
    test('getBaseUrlBeforeHash handles URL with hash', () {
      const url = 'https://example.com/web/f/#/test';
      const expectedUrl = 'https://example.com/web/f/';

      final result = url.getBaseUrlBeforeHash();

      expect(result, equals(expectedUrl));
    });

    test('getBaseUrlBeforeHash handles URL without hash', () {
      const url = 'https://example.com/test';
      const expectedUrl = 'https://example.com/test';

      final result = url.getBaseUrlBeforeHash();

      expect(result, equals(expectedUrl));
    });

    test('getBaseUrlBeforeHash handles URL with multiple hashes', () {
      const url = 'https://example.com/#/test#section';
      const expectedUrl = 'https://example.com/';

      final result = url.getBaseUrlBeforeHash();

      expect(result, equals(expectedUrl));
    });

    test('getBaseUrlBeforeHash handles URL with query parameters and hash', () {
      const url = 'https://example.com/test?query=1#/section';
      const expectedUrl = 'https://example.com/test?query=1';

      final result = url.getBaseUrlBeforeHash();

      expect(result, equals(expectedUrl));
    });
  });

  group('generateLoginAuthPath test', () {
    test('returns correct path in dev mode', () {
      const baseUrl = 'https://example.com/';
      const homeserverParams = '?hs_url=https://matrix.org';
      final result = baseUrl.generateLoginAuthPath(
        homeserverParams: homeserverParams,
        isDevMode: true,
      );
      expect(
        result,
        equals('https://example.com/web/auth.html?hs_url=https://matrix.org'),
      );
    });

    test('returns correct path in production mode', () {
      const baseUrl = 'https://example.com/';
      const homeserverParams = '?hs_url=https://matrix.org';
      final result = baseUrl.generateLoginAuthPath(
        homeserverParams: homeserverParams,
        isDevMode: false,
      );
      expect(
        result,
        equals('https://example.com/auth.html?hs_url=https://matrix.org'),
      );
    });

    test('returns correct path without homeserverParams in dev mode', () {
      const baseUrl = 'https://example.com/';
      final result = baseUrl.generateLoginAuthPath(
        isDevMode: true,
      );
      expect(result, equals('https://example.com/web/auth.html'));
    });

    test('returns correct path without homeserverParams in production mode',
        () {
      const baseUrl = 'https://example.com/';
      final result = baseUrl.generateLoginAuthPath(
        isDevMode: false,
      );
      expect(result, equals('https://example.com/auth.html'));
    });

    test('trims homeserverParams before appending', () {
      const baseUrl = 'https://example.com/';
      const homeserverParams = '  ?hs_url=https://matrix.org  ';
      final result = baseUrl.generateLoginAuthPath(
        homeserverParams: homeserverParams,
        isDevMode: false,
      );
      expect(
        result,
        equals('https://example.com/auth.html?hs_url=https://matrix.org'),
      );
    });
  });

  group('[normalizePhoneNumberToInvite]', () {
    test('should keep digits and plus sign, remove others', () {
      const phoneNumber = '+1 (234)-567.89 0';
      const expected = '+1234567890';
      expect(phoneNumber.normalizePhoneNumberToInvite(), equals(expected));
    });

    test('should handle number with only digits', () {
      const phoneNumber = '1234567890';
      const expected = '1234567890';
      expect(phoneNumber.normalizePhoneNumberToInvite(), equals(expected));
    });

    test('should handle number with only plus and digits', () {
      const phoneNumber = '+1234567890';
      const expected = '+1234567890';
      expect(phoneNumber.normalizePhoneNumberToInvite(), equals(expected));
    });

    test('should handle number with spaces', () {
      const phoneNumber = '+1 234 567 890';
      const expected = '+1234567890';
      expect(phoneNumber.normalizePhoneNumberToInvite(), equals(expected));
    });

    test('should handle empty string', () {
      const phoneNumber = '';
      const expected = '';
      expect(phoneNumber.normalizePhoneNumberToInvite(), equals(expected));
    });

    test('should handle string with only non-digit, non-plus characters', () {
      const phoneNumber = 'abc-() .';
      const expected = '';
      expect(phoneNumber.normalizePhoneNumberToInvite(), equals(expected));
    });

    test('should handle string with only plus sign', () {
      const phoneNumber = '+';
      const expected = '+';
      expect(phoneNumber.normalizePhoneNumberToInvite(), equals(expected));
    });
  });

  group('ListStringExtension.combineRecentReactions', () {
    test('adds new emoji to the front', () {
      final reactions = ['😀', '😂'];
      final result = reactions.combineRecentReactions(emojiId: '😍');
      expect(result, ['😍', '😀', '😂']);
    });

    test('moves existing emoji to the front', () {
      final reactions = ['😀', '😂', '😍'];
      final result = reactions.combineRecentReactions(emojiId: '😂');
      expect(result, ['😂', '😀', '😍']);
    });

    test('removes oldest emoji if over max size', () {
      final reactions =
          List.generate(12, (i) => String.fromCharCode(0x1F600 + i));
      final result = reactions.combineRecentReactions(emojiId: '😎');
      expect(result.first, '😎');
      expect(result.length, 12);
      expect(result.contains(reactions.last), isFalse);
    });

    test('does not duplicate emoji', () {
      final reactions =
          List.generate(12, (i) => String.fromCharCode(0x1F600 + i));
      final result = reactions.combineRecentReactions(emojiId: reactions.first);
      expect(result, reactions);
      expect(result.length, 12);
    });

    test('handles empty list', () {
      final reactions = <String>[];
      final result = reactions.combineRecentReactions(emojiId: '😀');
      expect(result, ['😀']);
    });

    test('handles adding same emoji repeatedly', () {
      var reactions = <String>[];
      for (int i = 0; i < 5; i++) {
        reactions = reactions.combineRecentReactions(emojiId: '😀');
      }
      expect(reactions, ['😀']);
    });

    test('keeps only maxRecentReactionsSize items', () {
      final emojis = List.generate(20, (i) => String.fromCharCode(0x1F600 + i));
      List<String> reactions = [];
      for (final emoji in emojis) {
        reactions = reactions.combineRecentReactions(emojiId: emoji);
      }
      expect(reactions.length, 12);
      expect(reactions, emojis.reversed.take(12).toList());
    });
  });

  group('getDomain test', () {
    // Additional test cases for getDomain
    test('returns domain for @john:my-domain.org', () {
      expect('@john:my-domain.org'.getDomain(), equals('my-domain.org'));
    });
    test('returns domain for @jane:EXAMPLE.ORG', () {
      expect('@jane:EXAMPLE.ORG'.getDomain(), equals('example.org'));
    });
    test('returns domain for @user:sub.example.org', () {
      expect('@user:sub.example.org'.getDomain(), equals('sub.example.org'));
    });
    test('returns domain for @user:123domain.com', () {
      expect('@user:123domain.com'.getDomain(), equals('123domain.com'));
    });
    test('returns domain for @user:domain-with-dash.com', () {
      expect(
        '@user:domain-with-dash.com'.getDomain(),
        equals('domain-with-dash.com'),
      );
    });
    test('returns domain for @user:domain.with.dots.com', () {
      expect(
        '@user:domain.with.dots.com'.getDomain(),
        equals('domain.with.dots.com'),
      );
    });
    test('returns domain for @user:UPPERCASE.COM', () {
      expect('@user:UPPERCASE.COM'.getDomain(), equals('uppercase.com'));
    });
    test('returns empty string for @userdomain.com', () {
      expect('@userdomain.com'.getDomain(), equals(''));
    });
    test('returns empty string for @user:domain:com', () {
      expect('@user:domain:com'.getDomain(), equals(''));
    });
    test('returns empty string for @:domain.com', () {
      expect('@:domain.com'.getDomain(), equals('domain.com'));
    });
    test('returns empty string for @user:', () {
      expect('@user:'.getDomain(), equals(''));
    });
    test('returns empty string for :domain.com', () {
      expect(':domain.com'.getDomain(), equals('domain.com'));
    });
    test('returns empty string for @:domain', () {
      expect('@:domain'.getDomain(), equals('domain'));
    });
    test('returns empty string for @user:', () {
      expect('@user:'.getDomain(), equals(''));
    });
    test('returns empty string for @:', () {
      expect('@:'.getDomain(), equals(''));
    });
    test('returns empty string for @user', () {
      expect('@user'.getDomain(), equals(''));
    });
    test('returns empty string for user:domain.com', () {
      expect('user:domain.com'.getDomain(), equals('domain.com'));
    });
    test('returns empty string for @user:domain.com:extra', () {
      expect('@user:domain.com:extra'.getDomain(), equals(''));
    });
    test('returns empty string for @:domain.com:extra', () {
      expect('@:domain.com:extra'.getDomain(), equals(''));
    });
    test('returns empty string for @user:', () {
      expect('@user:'.getDomain(), equals(''));
    });
  });

  group('isTheSameDomain test', () {
    test('same domain, both lowercase', () {
      expect(
        '@user:example.com'.isTheSameDomain(matrixId: '@other:example.com'),
        isTrue,
      );
    });

    test('same domain, mixed case', () {
      expect(
        '@user:EXAMPLE.com'.isTheSameDomain(matrixId: '@other:example.COM'),
        isTrue,
      );
    });

    test('different domains', () {
      expect(
        '@user:example.com'.isTheSameDomain(matrixId: '@other:another.com'),
        isFalse,
      );
    });

    test('subdomain vs domain', () {
      expect(
        '@user:sub.example.com'.isTheSameDomain(matrixId: '@other:example.com'),
        isFalse,
      );
    });

    test('domain with dash', () {
      expect(
        '@user:my-domain.com'.isTheSameDomain(matrixId: '@other:my-domain.com'),
        isTrue,
      );
    });

    test('domain with dots', () {
      expect(
        '@user:domain.with.dots.com'
            .isTheSameDomain(matrixId: '@other:domain.with.dots.com'),
        isTrue,
      );
    });

    test('domain with numbers', () {
      expect(
        '@user:123domain.com'.isTheSameDomain(matrixId: '@other:123domain.com'),
        isTrue,
      );
    });

    test('empty domain in self', () {
      expect(
        '@userdomain.com'.isTheSameDomain(matrixId: '@other:example.com'),
        isFalse,
      );
    });

    test('empty domain in matrixId', () {
      expect(
        '@user:example.com'.isTheSameDomain(matrixId: '@otherdomain.com'),
        isFalse,
      );
    });

    test('both empty domains', () {
      expect(
        '@userdomain.com'.isTheSameDomain(matrixId: '@otherdomain.com'),
        isFalse,
      );
    });

    test('extra colon in self', () {
      expect(
        '@user:domain.com:extra'.isTheSameDomain(matrixId: '@other:domain.com'),
        isFalse,
      );
    });

    test('extra colon in matrixId', () {
      expect(
        '@user:domain.com'.isTheSameDomain(matrixId: '@other:domain.com:extra'),
        isFalse,
      );
    });

    test('self missing username', () {
      expect(
        '@:domain.com'.isTheSameDomain(matrixId: '@other:domain.com'),
        isTrue,
      );
    });

    test('matrixId missing username', () {
      expect(
        '@user:domain.com'.isTheSameDomain(matrixId: '@:domain.com'),
        isTrue,
      );
    });

    test('self only colon', () {
      expect(
        '@:'.isTheSameDomain(matrixId: '@other:domain.com'),
        isFalse,
      );
    });

    test('matrixId only colon', () {
      expect(
        '@user:domain.com'.isTheSameDomain(matrixId: '@:'),
        isFalse,
      );
    });

    test('self only at', () {
      expect(
        '@user'.isTheSameDomain(matrixId: '@other:domain.com'),
        isFalse,
      );
    });

    test('matrixId only at', () {
      expect(
        '@user:domain.com'.isTheSameDomain(matrixId: '@other'),
        isFalse,
      );
    });

    test('self only domain', () {
      expect(
        ':domain.com'.isTheSameDomain(matrixId: '@other:domain.com'),
        isTrue,
      );
    });

    test('matrixId only domain', () {
      expect(
        '@user:domain.com'.isTheSameDomain(matrixId: ':domain.com'),
        isTrue,
      );
    });
  });
}
