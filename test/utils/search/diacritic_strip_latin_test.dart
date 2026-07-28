// Tests diacritic stripping with Latin script: one combining mark category per test (acute, grave, umlaut, etc.).
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = SearchEngine();
const _insensitive = SearchOptions(diacriticSensitive: false);

bool _match(String needle, String haystack) =>
    _engine.matchesText(needle, haystack, options: _insensitive);

void main() {
  group('matchesText latin with diacriticSensitive: false', () {
    test('should match acute accent (é → e)', () {
      expect(_match('elie', 'Élie'), isTrue);
    });

    test('should match grave accent (à → a)', () {
      expect(_match('a', 'à'), isTrue);
    });

    test('should match umlaut (ü → u)', () {
      expect(_match('uber', 'über'), isTrue);
    });

    test('should match tilde (ñ → n)', () {
      expect(_match('espana', 'España'), isTrue);
    });

    test('should match cedilla (ç → c)', () {
      expect(_match('francais', 'Français'), isTrue);
    });

    test('should match circumflex (ê → e)', () {
      expect(_match('fete', 'fête'), isTrue);
    });
  });

  group('matchesText latin: negative cases', () {
    test('should not match ß as ss (NFD does not expand ß)', () {
      expect(_match('ss', 'Straße'), isFalse);
    });

    test('should not match ä as ae (NFD strips the mark, does not expand)', () {
      expect(_match('ae', 'Ärzte'), isFalse);
    });

    test('should not match different base letter (u ≠ à)', () {
      expect(_match('u', 'à'), isFalse);
    });
  });

  test('should fold an accented needle, not just an accented haystack', () {
    expect(_match('Élie', 'elie'), isTrue);
  });
}
