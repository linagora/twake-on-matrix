// Tests diacritic stripping with Latin script: one combining mark category per test (acute, grave, umlaut, etc.).
import 'package:fluffychat/utils/search/simple_matcher_2.dart';
import 'package:flutter_test/flutter_test.dart';

const _matcher = SimpleMatcher2();

bool _match(String query, String candidate) =>
    _matcher.matchesText(query, candidate);

void main() {
  group('matchesText latin', () {
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

  test('should fold an accented query, not just an accented candidate', () {
    expect(_match('Élie', 'elie'), isTrue);
  });
}
