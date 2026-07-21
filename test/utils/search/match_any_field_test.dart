// Tests the matchAnyField/match/anyMatch API: multi-item filtering, single-item
// boolean checks, field extractors (including variable-length collection
// fields and the default toString() extractor), SearchOptions propagation,
// and special/regex-metacharacters in the needle (as opposed to the haystack,
// which is covered by the other files in this directory).
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = SearchEngine();

List<String> _search(
  String needle,
  List<String> haystack, {
  SearchOptions options = const SearchOptions(),
}) => _engine.matchAnyField(
  needle,
  haystack,
  fieldExtractors: [
    (String s) => [s],
  ],
  options: options,
);

void main() {
  _testDefaults();
  _testOptions();
  _testFieldExtractors();
  _testVariableLengthFields();
  _testMatch();
  _testAnyMatch();
  _testSpecialCharacterNeedles();
}

void _testDefaults() {
  group('matchAnyField default behavior', () {
    test('should return matching items on substring match', () {
      final result = _search('ell', ['hello', 'world']);

      expect(result, ['hello']);
    });

    test('should return all items when needle is empty', () {
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

    test('should match regardless of case by default', () {
      final result = _search('JOHN', ['John Smith', 'Jane Doe']);

      expect(result, ['John Smith']);
    });
  });
}

void _testOptions() {
  group('matchAnyField options', () {
    test('should not match different case when caseSensitive is true', () {
      final result = _search('john', [
        'John',
      ], options: const SearchOptions(caseSensitive: true));

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
        (Map<String, String> m) => [m['name'] ?? ''],
        (Map<String, String> m) => [m['email'] ?? ''],
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

      final result = _engine.matchAnyField(
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

      final result = _engine.matchAnyField(
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

        final result = _engine.matchAnyField(
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
      final result = _engine.match('ell', ['hello', 'world']);

      expect(result, ['hello']);
    });

    test('should match items via explicit field extractors', () {
      final items = [
        {'name': 'Alice', 'email': 'alice@example.com'},
        {'name': 'Bob', 'email': 'bob@example.com'},
      ];

      final result = _engine.match(
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

      final result = _engine.anyMatch(
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

      final result = _engine.anyMatch(
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

      final result = _engine.anyMatch(
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
        final result = _engine.anyMatch('ell', ['hello', 'world']);

        expect(result, true);
      },
    );
  });
}

void _testSpecialCharacterNeedles() {
  group('matchAnyField needle with special characters', () {
    test('should match a needle containing regex metacharacters literally', () {
      final result = _search('a.b', ['a.b.c', 'axbxc']);

      expect(result, ['a.b.c']);
    });

    test(
      'should not treat "." or "*" in the needle as regex wildcard/quantifier',
      () {
        expect(_search('.', ['hello', 'world']), isEmpty);
        expect(_search('a*', ['aaa', 'a*b']), ['a*b']);
      },
    );

    test('should fold diacritics on the needle, not just the haystack', () {
      final result = _engine.matchAnyField(
        'Élie',
        ['elie', 'other'],
        fieldExtractors: [
          (String s) => [s],
        ],
        options: const SearchOptions(diacriticSensitive: false),
      );

      expect(result, ['elie']);
    });

    test('should match an emoji needle literally', () {
      final result = _search('🔥', ['urgent 🔥 task', 'calm task']);

      expect(result, ['urgent 🔥 task']);
    });
  });
}
