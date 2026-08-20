// Tests the matchAnyField/match/anyMatch API: multi-item filtering, single-item
// boolean checks, field extractors (including variable-length collection
// fields and the default toString() extractor), and special/regex-metacharacters
// in the query (as opposed to the candidate, which is covered by the other files
// in this directory).
import 'package:fluffychat/utils/search/simple_matcher_2.dart';
import 'package:flutter_test/flutter_test.dart';

const _matcher = SimpleMatcher2();

List<String> _search(String query, List<String> haystack) =>
    _matcher.matchAnyField(
      query,
      haystack,
      fieldExtractors: [
        (String s) => [s],
      ],
    );

void main() {
  _testDefaults();
  _testFieldExtractors();
  _testVariableLengthFields();
  _testMatch();
  _testAnyMatch();
  _testSpecialCharacterNeedles();
}

void _testDefaults() {
  group('matchAnyField', () {
    test('should return matching items on substring match', () {
      final result = _search('ell', ['hello', 'world']);

      expect(result, ['hello']);
    });

    test('should return all items when query is empty', () {
      final result = _search('', ['hello']);

      expect(result, ['hello']);
    });

    test('should return empty list when nothing matches', () {
      final result = _search('xyz', ['hello', 'world']);

      expect(result, isEmpty);
    });

    test('should return original items, not normalized ones', () {
      final result = _search('john', ['John Smith']);

      expect(result, ['John Smith']);
    });

    test('should match regardless of case', () {
      final result = _search('JOHN', ['John Smith', 'Jane Doe']);

      expect(result, ['John Smith']);
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
        (Map<String, String> m) => [m['name'] ?? ''],
        (Map<String, String> m) => [m['email'] ?? ''],
      ];

      final resultName = _matcher.matchAnyField(
        'alice',
        items,
        fieldExtractors: extractors,
      );
      final resultEmail = _matcher.matchAnyField(
        'bob@',
        items,
        fieldExtractors: extractors,
      );

      expect(resultName, [items[0]]);
      expect(resultEmail, [items[1]]);
    });
  });
}

void _testVariableLengthFields() {
  group('matchAnyField variable-length field extractors', () {
    test('should not match an item whose collection field is empty', () {
      final items = [
        {'name': 'Alice', 'tags': <String>[]},
      ];
      final extractors = [
        (Map<String, Object> m) => [m['name'] as String],
        (Map<String, Object> m) => m['tags'] as List<String>,
      ];

      final result = _matcher.matchAnyField(
        'urgent',
        items,
        fieldExtractors: extractors,
      );

      expect(result, isEmpty);
    });

    test('should match an item via a single-element collection field', () {
      final items = [
        {
          'name': 'Alice',
          'tags': ['urgent'],
        },
        {
          'name': 'Bob',
          'tags': ['low-priority'],
        },
      ];
      final extractors = [
        (Map<String, Object> m) => [m['name'] as String],
        (Map<String, Object> m) => m['tags'] as List<String>,
      ];

      final result = _matcher.matchAnyField(
        'urgent',
        items,
        fieldExtractors: extractors,
      );

      expect(result, [items[0]]);
    });

    test(
      'should match an item via any element of a multi-element collection field',
      () {
        final items = [
          {
            'name': 'Alice',
            'tags': ['billing', 'urgent', 'follow-up'],
          },
          {
            'name': 'Bob',
            'tags': ['low-priority'],
          },
        ];
        final extractors = [
          (Map<String, Object> m) => [m['name'] as String],
          (Map<String, Object> m) => m['tags'] as List<String>,
        ];

        final result = _matcher.matchAnyField(
          'urgent',
          items,
          fieldExtractors: extractors,
        );

        expect(result, [items[0]]);
      },
    );
  });
}

void _testMatch() {
  group('match', () {
    test('should match items via the default toString() extractor', () {
      final result = _matcher.match('ell', ['hello', 'world']);

      expect(result, ['hello']);
    });

    test('should match items via explicit field extractors', () {
      final items = [
        {'name': 'Alice', 'email': 'alice@example.com'},
        {'name': 'Bob', 'email': 'bob@example.com'},
      ];

      final result = _matcher.match(
        'bob@',
        items,
        fieldExtractors: [
          (Map<String, String> m) => [m['name'] ?? ''],
          (Map<String, String> m) => [m['email'] ?? ''],
        ],
      );

      expect(result, [items[1]]);
    });
  });
}

void _testAnyMatch() {
  group('anyMatch', () {
    test('should return true when a scalar field matches', () {
      final item = {'name': 'Alice', 'email': 'alice@example.com'};

      final result = _matcher.anyMatch(
        'alice',
        [item],
        fieldExtractors: [
          (Map<String, String> m) => [m['name'] ?? ''],
          (Map<String, String> m) => [m['email'] ?? ''],
        ],
      );

      expect(result, true);
    });

    test('should return true when a collection field matches', () {
      final item = {
        'name': 'Alice',
        'tags': ['urgent'],
      };

      final result = _matcher.anyMatch(
        'urgent',
        [item],
        fieldExtractors: [
          (Map<String, Object> m) => [m['name'] as String],
          (Map<String, Object> m) => m['tags'] as List<String>,
        ],
      );

      expect(result, true);
    });

    test('should return false when no field matches', () {
      final item = {
        'name': 'Alice',
        'tags': ['urgent'],
      };

      final result = _matcher.anyMatch(
        'zzz',
        [item],
        fieldExtractors: [
          (Map<String, Object> m) => [m['name'] as String],
          (Map<String, Object> m) => m['tags'] as List<String>,
        ],
      );

      expect(result, false);
    });

    test(
      'should match via the default toString() extractor when none provided',
      () {
        final result = _matcher.anyMatch('ell', ['hello', 'world']);

        expect(result, true);
      },
    );
  });
}

void _testSpecialCharacterNeedles() {
  group('matchAnyField query with special characters', () {
    test('should match a query containing regex metacharacters literally', () {
      final result = _search('a.b', ['a.b.c', 'axbxc']);

      expect(result, ['a.b.c']);
    });

    test(
      'should not treat "." or "*" in the query as regex wildcard/quantifier',
      () {
        expect(_search('.', ['hello', 'world']), isEmpty);
        expect(_search('a*', ['aaa', 'a*b']), ['a*b']);
      },
    );

    test('should fold diacritics on the query, not just the candidate', () {
      final result = _search('Élie', ['elie', 'other']);

      expect(result, ['elie']);
    });

    test('should match an emoji query literally', () {
      final result = _search('🔥', ['urgent 🔥 task', 'calm task']);

      expect(result, ['urgent 🔥 task']);
    });
  });
}
