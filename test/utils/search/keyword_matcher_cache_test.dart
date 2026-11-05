// Tests that the matcher is built once per keyword and that results stay
// identical to the one-shot SearchEngine.matchesText for accent/case variants.
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/search/keyword_matcher_cache.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/utils/search/search_options.dart';

class _CountingSearchEngine extends SearchEngine {
  _CountingSearchEngine();

  int builds = 0;

  @override
  SearchMatcher buildMatcher(
    String needle, {
    SearchOptions options = const SearchOptions(),
  }) {
    builds++;
    return super.buildMatcher(needle, options: options);
  }
}

void main() {
  const options = SearchOptions(diacriticSensitive: false);
  const reference = SearchEngine();

  const bodies = [
    'Hello Böb',
    'hello bob',
    'HELLO BOB',
    'Nguyễn Văn A',
    'nguyen van a',
    'Привет мир',
    'unrelated',
    '',
  ];
  const keywords = ['bob', 'Böb', 'BOB', 'nguyen van', 'Nguyễn', 'привет', ''];

  late _CountingSearchEngine engine;
  late KeywordMatcherCache cache;

  setUp(() {
    engine = _CountingSearchEngine();
    cache = KeywordMatcherCache(engine: engine, options: options);
  });

  test('builds the matcher once for many values of the same keyword', () {
    for (final body in bodies) {
      cache.matches('bob', body);
    }

    expect(engine.builds, 1);
  });

  test('rebuilds only when the keyword changes', () {
    for (final keyword in keywords) {
      for (final body in bodies) {
        cache.matches(keyword, body);
      }
    }

    expect(engine.builds, keywords.length);
  });

  test('null keyword behaves like the empty keyword', () {
    expect(cache.matches(null, 'Hello'), isTrue);
    expect(cache.matches('', 'Hello'), isTrue);
    expect(engine.builds, 1);
  });

  test('results are identical to SearchEngine.matchesText', () {
    for (final keyword in keywords) {
      for (final body in bodies) {
        expect(
          cache.matches(keyword, body),
          reference.matchesText(keyword, body, options: options),
          reason: 'keyword="$keyword" body="$body"',
        );
      }
    }
  });

  test('accented, unaccented and case variants match as before', () {
    expect(cache.matches('bob', 'Hello Böb'), isTrue);
    expect(cache.matches('Böb', 'hello bob'), isTrue);
    expect(cache.matches('NGUYEN', 'Nguyễn Văn A'), isTrue);
    expect(cache.matches('alice', 'Hello Böb'), isFalse);
  });
}
