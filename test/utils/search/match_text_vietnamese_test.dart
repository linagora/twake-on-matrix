// Vietnamese uses tone marks stacked on top of vowel modifications.
// NFD decomposes these into a base letter + combining marks (category Mn),
// which are then stripped — so the base letter survives.
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = SearchEngine();
const _insensitive = SearchOptions(diacriticSensitive: false);

bool _match(String needle, String haystack) =>
    _engine.matchesText(needle, haystack, options: _insensitive);

void main() {
  group('matchesText vietnamese — diacriticSensitive: false', () {
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
}
