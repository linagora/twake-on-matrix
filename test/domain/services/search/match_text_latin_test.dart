import 'package:fluffychat/domain/services/search/search_options.dart';
import 'package:fluffychat/domain/services/search/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = SearchEngine();
const _insensitive = SearchOptions(diacriticSensitive: false);

bool _match(
  String needle,
  String haystack, {
  SearchOptions options = const SearchOptions(),
}) => _engine.matchesText(needle, haystack, options: options);

void main() {
  _testDefaults();
  _testDiacriticInsensitive();
}

void _testDefaults() {
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

void _testDiacriticInsensitive() {
  group('matchesText latin — diacriticSensitive: false', () {
    test('should match acute accent (é → e)', () {
      expect(_match('elie', 'Élie', options: _insensitive), isTrue);
    });

    test('should match grave accent (à → a)', () {
      expect(_match('a', 'à', options: _insensitive), isTrue);
    });

    test('should match umlaut (ü → u)', () {
      expect(_match('uber', 'über', options: _insensitive), isTrue);
    });

    test('should match tilde (ñ → n)', () {
      expect(_match('espana', 'España', options: _insensitive), isTrue);
    });

    test('should match cedilla (ç → c)', () {
      expect(_match('francais', 'Français', options: _insensitive), isTrue);
    });

    test('should match circumflex (ê → e)', () {
      expect(_match('fete', 'fête', options: _insensitive), isTrue);
    });
  });
}
