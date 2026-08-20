// Stress-tests diacritic stripping with Vietnamese: stacked marks (tone + vowel modification)
// that NFD decomposes into multiple combining characters, all stripped to the base letter.
// Also verifies that stripping never collapses distinct base letters into each other.
import 'package:fluffychat/utils/search/simple_matcher_2.dart';
import 'package:flutter_test/flutter_test.dart';

const _matcher = SimpleMatcher2();

bool _match(String query, String candidate) =>
    _matcher.matchesText(query, candidate);

void main() {
  group('matchesText vietnamese', () {
    test('should match ă and â (a variants)', () {
      expect(_match('ban', 'băn'), isTrue);
      expect(_match('ban', 'bân'), isTrue);
    });

    test('should match ê (e with circumflex)', () {
      expect(_match('kep', 'kẹp'), isTrue);
    });

    test('should match ô and ơ (o variants)', () {
      expect(_match('bo', 'bô'), isTrue);
      expect(_match('bo', 'bơ'), isTrue);
    });

    test('should match ư (u with horn)', () {
      expect(_match('bu', 'bư'), isTrue);
    });

    test('should match full name Nguyễn', () {
      expect(_match('nguyen', 'Nguyễn'), isTrue);
    });

    test('should match Việt Nam', () {
      expect(_match('viet nam', 'Việt Nam'), isTrue);
    });

    test('should match phở (o with horn and hook)', () {
      expect(_match('pho', 'phở'), isTrue);
    });

    test('should match Hà Nội (stacked tone + dot below)', () {
      expect(_match('ha noi', 'Hà Nội'), isTrue);
    });
  });

  group('matchesText vietnamese — should not match', () {
    test('should not match different final consonant (bam ≠ băn)', () {
      expect(_match('bam', 'băn'), isFalse);
    });

    test('should not match different base vowel (ben ≠ bân)', () {
      expect(_match('ben', 'bân'), isFalse);
    });

    test('should not match different base consonant (ca ≠ ta)', () {
      expect(_match('ca', 'ta'), isFalse);
    });

    test('should not match when query is longer than candidate word', () {
      expect(_match('nguyenlan', 'Nguyễn'), isFalse);
    });
  });

  test('should fold an accented query, not just an accented candidate', () {
    expect(_match('Nguyễn', 'nguyen'), isTrue);
  });
}
