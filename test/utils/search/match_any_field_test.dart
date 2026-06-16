import 'package:fluffychat/domain/model/search/search_options.dart';
import 'package:fluffychat/utils/search/text_search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = TextSearchEngine();

List<String> _search(
  String needle,
  List<String> haystack, {
  SearchOptions options = const SearchOptions(),
}) => _engine.matchAnyField(
  needle,
  haystack,
  fieldExtractors: [(String s) => s],
  options: options,
);

void main() {
  _testDefaults();
  _testOptions();
  _testFieldExtractors();
}

void _testDefaults() {
  group('matchAnyField default behavior', () {
    test('should return matching items on substring match', () {
      final result = _search('ell', ['hello', 'world']);

      expect(result, ['hello']);
    });

    test('should return empty list when needle is empty', () {
      final result = _search('', ['hello']);

      expect(result, isEmpty);
    });

    test('should return empty list when nothing matches', () {
      final result = _search('xyz', ['hello', 'world']);

      expect(result, isEmpty);
    });

    test('should return original items, not normalized ones', () {
      final result = _search('john', ['John Smith']);

      expect(result, ['John Smith']);
    });

    test('should match regardless of case by default', () {
      final result = _search('JOHN', ['John Smith', 'Jane Doe']);

      expect(result, ['John Smith']);
    });
  });
}

void _testOptions() {
  group('matchAnyField options', () {
    test('should not match different case when caseSensitive is true', () {
      final result = _search(
        'john',
        ['John'],
        options: const SearchOptions(caseSensitive: true),
      );

      expect(result, isEmpty);
    });
  });
}

void _testFieldExtractors() {
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

      final resultName = _engine.matchAnyField(
        'alice',
        items,
        fieldExtractors: extractors,
      );
      final resultEmail = _engine.matchAnyField(
        'bob@',
        items,
        fieldExtractors: extractors,
      );

      expect(resultName, [items[0]]);
      expect(resultEmail, [items[1]]);
    });
  });
}