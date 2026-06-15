import 'package:fluffychat/domain/model/search/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _search(
  String needle,
  List<String> haystack, {
  SearchOptions options = const SearchOptions(),
}) => matchAnyField(
  needle,
  haystack,
  fieldExtractors: [(String s) => s],
  options: options,
);

void main() {
  group('matchAnyField', () {
    group('default options (case+diacritic insensitive, substring)', () {
      test(
        'matches substring',
        () => expect(_search('ell', ['hello', 'world']), ['hello']),
      );
      test(
        'is case insensitive',
        () =>
            expect(_search('JOHN', ['John Smith', 'Jane Doe']), ['John Smith']),
      );
      test(
        'is diacritic insensitive',
        () => expect(_search('elie', ['Élie', 'Bob']), ['Élie']),
      );
      test(
        'returns empty list for empty needle',
        () => expect(_search('', ['hello']), isEmpty),
      );
      test(
        'returns empty list when nothing matches',
        () => expect(_search('xyz', ['hello', 'world']), isEmpty),
      );
      test(
        'returns original items, not normalized ones',
        () => expect(_search('john', ['John Smith']), ['John Smith']),
      );
    });

    group('SearchMode.exact', () {
      test(
        'matches exact string',
        () => expect(
          _search('hello', [
            'hello',
            'hello world',
          ], options: const SearchOptions(mode: SearchMode.exact)),
          ['hello'],
        ),
      );
    });

    group('multiple field extractors', () {
      final items = [
        {'name': 'Alice', 'email': 'alice@example.com'},
        {'name': 'Bob', 'email': 'bob@example.com'},
      ];
      final extractors = [
        (Map<String, String> m) => m['name'],
        (Map<String, String> m) => m['email'],
      ];

      test(
        'matches on name field',
        () => expect(
          matchAnyField('alice', items, fieldExtractors: extractors),
          [items[0]],
        ),
      );
      test(
        'matches on email field',
        () => expect(
          matchAnyField('bob@', items, fieldExtractors: extractors),
          [items[1]],
        ),
      );
    });

    group('caseSensitive: true', () {
      test(
        'does not match different case',
        () => expect(
          _search('john', [
            'John',
          ], options: const SearchOptions(caseSensitive: true)),
          isEmpty,
        ),
      );
    });

    group('custom pipeline override', () {
      test(
        'uses provided steps instead of defaults',
        () => expect(
          _search('hello', [
            'HELLO',
          ], options: const SearchOptions(normalize: [])),
          isEmpty,
        ),
      );
    });
  });

  group('matchesText', () {
    test(
      'returns true when needle is found',
      () => expect(matchesText('ell', 'hello'), isTrue),
    );
    test(
      'returns false when needle is not found',
      () => expect(matchesText('xyz', 'hello'), isFalse),
    );
    test(
      'is case insensitive by default',
      () => expect(matchesText('HELLO', 'hello world'), isTrue),
    );
    test(
      'is diacritic insensitive by default',
      () => expect(matchesText('elie', 'Élie'), isTrue),
    );
    test(
      'returns false for empty needle',
      () => expect(matchesText('', 'hello'), isFalse),
    );
  });
}
