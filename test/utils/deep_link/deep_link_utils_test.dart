import 'dart:convert';

import 'package:fluffychat/presentation/model/deep_link/deep_link.dart';
import 'package:fluffychat/utils/deep_link/deep_link_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkUtils.parseDeepLink', () {
    test('returns DeepLink when url is valid', () {
      const url = 'twake.chat://openapp?loginToken=abc123&data={"homeServer":"example.com","userId":"userA"}';
      final result = DeepLinkUtils.parseDeepLink(url);

      expect(result, isA<DeepLink>());
      expect(result?.scheme, 'twake.chat');
      expect(result?.host, 'openapp');
      expect(result?.queryParameters!['loginToken'], 'abc123');
      expect(result?.queryParameters!['data'], '{"homeServer":"example.com","userId":"userA"}');
    });

    test('returns null when url is malformed', () {
      const url = '%%%invalidurl';
      final result = DeepLinkUtils.parseDeepLink(url);

      expect(result, isNull);
    });

    test('returns DeepLink with empty query params', () {
      const url = 'twake.chat://openapp';
      final result = DeepLinkUtils.parseDeepLink(url);

      expect(result, isA<DeepLink>());
      expect(result?.scheme, 'twake.chat');
      expect(result?.host, 'openapp');
      expect(result?.queryParameters, isEmpty);
    });
  });

  group('parseOpenAppDeepLink', () {
    test('returns null when queryParameters is null', () {
      final result = DeepLinkUtils.parseOpenAppDeepLink(null);
      expect(result, isNull);
    });

    test('returns null when queryParameters is empty', () {
      final result = DeepLinkUtils.parseOpenAppDeepLink({});
      expect(result, isNull);
    });

    test('returns null when data is missing', () {
      final result = DeepLinkUtils.parseOpenAppDeepLink({'loginToken': 'abc'});
      expect(result, isNull);
    });

    test('returns null when data is empty', () {
      final result = DeepLinkUtils.parseOpenAppDeepLink({
        'loginToken': 'abc',
        'data': '',
      });
      expect(result, isNull);
    });

    test('returns null when data is invalid JSON', () {
      final result = DeepLinkUtils.parseOpenAppDeepLink({
        'loginToken': 'abc',
        'data': 'invalid_json',
      });
      expect(result, isNull);
    });

    test('returns object when data is valid and loginToken is present', () {
      final dataJson = jsonEncode({
        'homeServer': 'example.org',
        'userId': '@user:example.org',
      });

      final result = DeepLinkUtils.parseOpenAppDeepLink({
        'loginToken': 'token123',
        'data': dataJson,
      });

      expect(result, isNotNull);
      expect(result!.loginToken, 'token123');
      expect(result.homeServer, 'example.org');
      expect(result.userId, '@user:example.org');
    });

    test('returns object when loginToken is missing', () {
      final dataJson = jsonEncode({
        'homeServer': 'matrix.org',
        'userId': '@someone:matrix.org',
      });

      final result = DeepLinkUtils.parseOpenAppDeepLink({
        'data': dataJson,
      });

      expect(result, isNotNull);
      expect(result!.loginToken, '');
      expect(result.homeServer, 'matrix.org');
      expect(result.userId, '@someone:matrix.org');
    });

    test('handles missing homeServer and userId gracefully', () {
      final dataJson = jsonEncode({});

      final result = DeepLinkUtils.parseOpenAppDeepLink({
        'loginToken': 'abc',
        'data': dataJson,
      });

      expect(result, isNotNull);
      expect(result!.loginToken, 'abc');
      expect(result.homeServer, '');
      expect(result.userId, '');
    });
  });
}
