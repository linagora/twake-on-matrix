// Tests matchRanges: the position-returning counterpart to matchesText, used to
// drive highlighting. Verifies both whether a match is found and that returned
// offsets are correct in the *original* (non-normalized) string.
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = SearchEngine();
const _insensitive = SearchOptions(diacriticSensitive: false);

List<MatchRange> _ranges(
  String needle,
  String haystack, {
  SearchOptions options = _insensitive,
}) => _engine.matchRanges(needle, haystack, options: options);

void main() {
  group('matchRanges — plain substring', () {
    test('should return the range of a plain substring match', () {
      expect(_ranges('ell', 'hello'), [(start: 1, end: 4)]);
    });

    test('should match regardless of case', () {
      expect(_ranges('HELLO', 'hello world'), [(start: 0, end: 5)]);
    });

    test('should return an empty list when there is no match', () {
      expect(_ranges('xyz', 'hello'), isEmpty);
    });

    test('should return an empty list for an empty needle', () {
      expect(_ranges('', 'hello'), isEmpty);
    });

    test('should return a range at the very start of the haystack', () {
      expect(_ranges('he', 'hello'), [(start: 0, end: 2)]);
    });

    test('should return a range at the very end of the haystack', () {
      expect(_ranges('llo', 'hello'), [(start: 2, end: 5)]);
    });

    test('should return all non-overlapping occurrences', () {
      expect(_ranges('an', 'banana'), [(start: 1, end: 3), (start: 3, end: 5)]);
    });

    test(
      'should match a needle containing regex-special characters literally',
      () {
        expect(_ranges('a.b\\c', 'prefix a.b\\c suffix'), [
          (start: 7, end: 12),
        ]);
      },
    );

    test('should not include trailing zero-width runes in the match range', () {
      // Regression test: haystack = "hello" + U+0301 (combining mark that normalizes to "")
      // The match "hello" should end at code unit 5, not include the trailing U+0301.
      final haystack = 'hello${String.fromCharCode(0x0301)}';
      expect(
        _ranges(
          'hello',
          haystack,
          options: const SearchOptions(diacriticSensitive: false),
        ),
        [(start: 0, end: 5)],
      );
    });
  });

  group('matchRanges — diacritic-insensitive offsets', () {
    test(
      'should map a normalized match back to the accented original (é → e)',
      () {
        // "Élie" is 4 UTF-16 code units; the whole word matches "elie".
        expect(_ranges('elie', 'Élie'), [(start: 0, end: 4)]);
      },
    );

    test(
      'should return correct offsets when the match is not at the start',
      () {
        expect(_ranges('elie', 'Bonjour Élie'), [(start: 8, end: 12)]);
      },
    );

    test('should map offsets correctly for stacked Vietnamese diacritics', () {
      // "Nguyễn" — ễ is a single precomposed code unit; the whole word matches.
      expect(_ranges('nguyen', 'Nguyễn'), [(start: 0, end: 6)]);
    });

    test(
      'should map offsets correctly for pre-decomposed (already-NFD) input',
      () {
        // "e" + combining acute accent (U+0301) — two UTF-16 code units for
        // one visual character "é" — followed by "lie". The match must span
        // both code units of the decomposed character.
        final decomposed = String.fromCharCodes([
          0x65,
          0x0301,
          0x6C,
          0x69,
          0x65,
        ]);
        expect(_ranges('elie', decomposed), [(start: 0, end: 5)]);
      },
    );
  });

  group('matchRanges — text with astral characters', () {
    test(
      'should return correct offsets for a match after an emoji (surrogate pair)',
      () {
        // 😀 (U+1F600) takes 2 UTF-16 code units.
        expect(_ranges('hello', '😀 hello'), [(start: 3, end: 8)]);
      },
    );
  });

  group('matchRanges — exact mode', () {
    const exactInsensitive = SearchOptions(
      diacriticSensitive: false,
      mode: SearchMode.exact,
    );

    test(
      'should return the full range when the whole haystack matches exactly',
      () {
        expect(_ranges('elie', 'Élie', options: exactInsensitive), [
          (start: 0, end: 4),
        ]);
      },
    );

    test(
      'should return an empty list when the haystack is only a partial match',
      () {
        expect(
          _ranges('elie', 'Bonjour Élie', options: exactInsensitive),
          isEmpty,
        );
      },
    );
  });
}
