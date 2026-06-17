import 'package:fluffychat/utils/search/search_options.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = SearchEngine();
const _insensitive = SearchOptions(diacriticSensitive: false);

bool _match(String needle, String haystack) =>
    _engine.matchesText(needle, haystack, options: _insensitive);

void main() {
  group('matchesText latin — diacriticSensitive: false', () {
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
}
