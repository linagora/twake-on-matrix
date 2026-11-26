// Issue #2014: a Russian word typed with a capital letter must find the
// same results as in lower case.
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/utils/search/search_options.dart';

const _engine = SearchEngine();

void main() {
  group('matchesText cyrillic — default options', () {
    test('should match a capitalized needle against a lower-case value', () {
      expect(_engine.matchesText('Привет', 'привет всем'), isTrue);
    });

    test('should match a lower-case needle against a capitalized value', () {
      expect(_engine.matchesText('москва', 'Москва'), isTrue);
    });

    test('should match an upper-case needle inside a value', () {
      expect(_engine.matchesText('ИВАН', 'Пётр Иванович'), isTrue);
    });

    test('should not match different words', () {
      expect(_engine.matchesText('Москва', 'Минск'), isFalse);
    });
  });

  group('matchesText cyrillic — caseSensitive: true', () {
    const sensitive = SearchOptions(caseSensitive: true);

    test('should not match when only the case differs', () {
      expect(
        _engine.matchesText('Привет', 'привет', options: sensitive),
        isFalse,
      );
    });
  });
}
