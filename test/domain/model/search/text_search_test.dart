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
  _testMatchAnyField();
  _testMatchesText();
}

void _testMatchAnyField() {
  _testMatchAnyFieldDefaults();
  _testMatchAnyFieldOptions();
  _testMatchAnyFieldExtractors();
}

void _testMatchAnyFieldDefaults() {
  group('matchAnyField default behavior', () {
    test('should return matching items on substring match', () {
      final haystack = ['hello', 'world'];

      final result = _search('ell', haystack);

      expect(result, ['hello']);
    });

    test('should return empty list when needle is empty', () {
      final haystack = ['hello'];

      final result = _search('', haystack);

      expect(result, isEmpty);
    });

    test('should return empty list when nothing matches', () {
      final haystack = ['hello', 'world'];

      final result = _search('xyz', haystack);

      expect(result, isEmpty);
    });

    test('should return original items, not normalized ones', () {
      final haystack = ['John Smith'];

      final result = _search('john', haystack);

      expect(result, ['John Smith']);
    });

    test('should match regardless of case by default', () {
      final haystack = ['John Smith', 'Jane Doe'];

      final result = _search('JOHN', haystack);

      expect(result, ['John Smith']);
    });

    test('should match regardless of diacritics by default', () {
      final haystack = ['Élie', 'Bob'];

      final result = _search('elie', haystack);

      expect(result, ['Élie']);
    });
  });
}

void _testMatchAnyFieldOptions() {
  group('matchAnyField options', () {
    test('should not match different case when caseSensitive is true', () {
      final haystack = ['John'];

      final result = _search(
        'john',
        haystack,
        options: const SearchOptions(caseSensitive: true),
      );

      expect(result, isEmpty);
    });

    test('should match exact string only when mode is exact', () {
      final haystack = ['hello', 'hello world'];

      final result = _search(
        'hello',
        haystack,
        options: const SearchOptions(mode: SearchMode.exact),
      );

      expect(result, ['hello']);
    });

    test('should use provided pipeline instead of defaults', () {
      final haystack = ['HELLO'];

      final result = _search(
        'hello',
        haystack,
        options: const SearchOptions(normalize: []),
      );

      expect(result, isEmpty);
    });
  });
}

void _testMatchAnyFieldExtractors() {
  group('matchAnyField field extractors', () {
    test('should match on any of the provided field extractors', () {
      final items = [
        {'name': 'Alice', 'email': 'alice@example.com'},
        {'name': 'Bob', 'email': 'bob@example.com'},
      ];
      final extractors = [
        (Map<String, String> m) => m['name'],
        (Map<String, String> m) => m['email'],
      ];

      final resultName = matchAnyField(
        'alice',
        items,
        fieldExtractors: extractors,
      );
      final resultEmail = matchAnyField(
        'bob@',
        items,
        fieldExtractors: extractors,
      );

      expect(resultName, [items[0]]);
      expect(resultEmail, [items[1]]);
    });
  });
}

void _testMatchesText() {
  group('matchesText', () {
    test('should return true when needle is found in haystack', () {
      final result = matchesText('ell', 'hello');

      expect(result, isTrue);
    });

    test('should return false when needle is not found in haystack', () {
      final result = matchesText('xyz', 'hello');

      expect(result, isFalse);
    });

    test('should return false when needle is empty', () {
      final result = matchesText('', 'hello');

      expect(result, isFalse);
    });

    test('should match regardless of case by default', () {
      final result = matchesText('HELLO', 'hello world');

      expect(result, isTrue);
    });

    test('should match regardless of diacritics by default', () {
      final result = matchesText('elie', 'Élie');

      expect(result, isTrue);
    });
  });
}
