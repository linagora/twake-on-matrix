import 'package:fluffychat/domain/model/search/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchAnyField', () {
    group('default options (case+diacritic insensitive, substring)', () {
      test('matches substring', () {
        expect(
          matchAnyField('ell', ['hello', 'world'],
              fieldExtractors: [(String s) => s]),
          ['hello'],
        );
      });

      test('is case insensitive', () {
        expect(
          matchAnyField('JOHN', ['John Smith', 'Jane Doe'],
              fieldExtractors: [(String s) => s]),
          ['John Smith'],
        );
      });

      test('is diacritic insensitive', () {
        expect(
          matchAnyField('elie', ['Élie', 'Bob'],
              fieldExtractors: [(String s) => s]),
          ['Élie'],
        );
      });

      test('returns empty list for empty needle', () {
        expect(
          matchAnyField('', ['hello'], fieldExtractors: [(String s) => s]),
          isEmpty,
        );
      });

      test('returns empty list when nothing matches', () {
        expect(
          matchAnyField('xyz', ['hello', 'world'],
              fieldExtractors: [(String s) => s]),
          isEmpty,
        );
      });

      test('returns original items, not normalized ones', () {
        final results = matchAnyField('john', ['John Smith'],
            fieldExtractors: [(String s) => s]);
        expect(results, ['John Smith']);
      });
    });

    group('SearchMode.exact', () {
      test('matches exact string', () {
        expect(
          matchAnyField('hello', ['hello', 'hello world'],
              fieldExtractors: [(String s) => s],
              options: const SearchOptions(mode: SearchMode.exact)),
          ['hello'],
        );
      });
    });

    group('multiple field extractors', () {
      final items = [
        {'name': 'Alice', 'email': 'alice@example.com'},
        {'name': 'Bob', 'email': 'bob@example.com'},
      ];

      test('matches on any field', () {
        final results = matchAnyField(
          'alice',
          items,
          fieldExtractors: [
            (Map<String, String> m) => m['name'],
            (Map<String, String> m) => m['email'],
          ],
        );
        expect(results, [items[0]]);
      });

      test('matches on second field', () {
        final results = matchAnyField(
          'bob@',
          items,
          fieldExtractors: [
            (Map<String, String> m) => m['name'],
            (Map<String, String> m) => m['email'],
          ],
        );
        expect(results, [items[1]]);
      });
    });

    group('caseSensitive: true', () {
      test('does not match different case', () {
        expect(
          matchAnyField('john', ['John'],
              fieldExtractors: [(String s) => s],
              options: const SearchOptions(caseSensitive: true)),
          isEmpty,
        );
      });
    });

    group('custom pipeline override', () {
      test('uses provided steps instead of defaults', () {
        expect(
          matchAnyField('hello', ['HELLO'],
              fieldExtractors: [(String s) => s],
              options: const SearchOptions(normalize: [])),
          isEmpty,
        );
      });
    });
  });

  group('matchesText', () {
    test('returns true when needle is found', () {
      expect(matchesText('ell', 'hello'), isTrue);
    });

    test('returns false when needle is not found', () {
      expect(matchesText('xyz', 'hello'), isFalse);
    });

    test('is case insensitive by default', () {
      expect(matchesText('HELLO', 'hello world'), isTrue);
    });

    test('is diacritic insensitive by default', () {
      expect(matchesText('elie', 'Élie'), isTrue);
    });

    test('returns false for empty needle', () {
      expect(matchesText('', 'hello'), isFalse);
    });
  });
}