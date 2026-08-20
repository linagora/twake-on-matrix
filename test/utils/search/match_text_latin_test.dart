// Tests the matchesText core contract: substring matching, case folding, and empty-query edge cases.
import 'package:fluffychat/utils/search/simple_matcher_2.dart';
import 'package:flutter_test/flutter_test.dart';

const _matcher = SimpleMatcher2();

bool _match(String query, String candidate) =>
    _matcher.matchesText(query, candidate);

void main() {
  group('matchesText latin', () {
    test('should return true when query is found in candidate', () {
      expect(_match('ell', 'hello'), isTrue);
    });

    test('should return false when query is not found in candidate', () {
      expect(_match('xyz', 'hello'), isFalse);
    });

    test('should return true when query is empty', () {
      expect(_match('', 'hello'), isTrue);
    });

    test('should match regardless of case', () {
      expect(_match('HELLO', 'hello world'), isTrue);
    });

    test('should fold diacritics', () {
      expect(_match('elie', 'Élie'), isTrue);
    });
  });
}
