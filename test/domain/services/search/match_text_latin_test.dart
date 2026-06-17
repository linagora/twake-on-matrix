import 'package:fluffychat/domain/services/search/search_options.dart';
import 'package:fluffychat/domain/services/search/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = SearchEngine();

bool _match(
  String needle,
  String haystack, {
  SearchOptions options = const SearchOptions(),
}) => _engine.matchesText(needle, haystack, options: options);

void main() {
  group('matchesText latin — default behavior', () {
    test('should return true when needle is found in haystack', () {
      expect(_match('ell', 'hello'), isTrue);
    });

    test('should return false when needle is not found in haystack', () {
      expect(_match('xyz', 'hello'), isFalse);
    });

    test('should return false when needle is empty', () {
      expect(_match('', 'hello'), isFalse);
    });

    test('should match regardless of case by default', () {
      expect(_match('HELLO', 'hello world'), isTrue);
    });

    test('should preserve diacritics by default', () {
      expect(_match('elie', 'Élie'), isFalse);
    });
  });
}
