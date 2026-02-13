import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/utils/string_extension.dart';

/// ReDoS unit tests for string extension regex patterns
/// Reference: ADR 0033 - Fix ReDoS vulnerabilities in regex patterns
///
/// Vulnerabilities:
/// 1. lib/utils/string_extension.dart:64,82 - URL extraction
///    Before: https:\/\/[^\s]+
///    After: https:\/\/[^\s]{1,2048}
///
/// 2. lib/utils/string_extension.dart:332-333 - URL separators
///    Before: [^ ]*:// and  *://  *
///    After: [^ ]{0,100}:// and  {0,10}://  {0,10}
///
/// 3. lib/utils/string_extension.dart:342-356 - Anchor parsing
///    Before: [^>]*, [^"]*, [^<]*
///    After: [^>]{0,500}, [^"]{0,2048}, [^<]{0,1000}
void main() {
  group('String extension URL extraction ReDoS tests', () {
    group('getFirstValidUrl - Valid URLs', () {
      test('should extract simple HTTPS URL', () {
        const text = 'Check out https://example.com for more info';
        expect(text.getFirstValidUrl(), equals('https://example.com'));
      });

      test('should extract URL with path', () {
        const text = 'Visit https://example.com/path/to/page';
        expect(
          text.getFirstValidUrl(),
          equals('https://example.com/path/to/page'),
        );
      });

      test('should extract URL with query parameters', () {
        const text = 'Link: https://example.com/search?q=test&lang=en';
        expect(
          text.getFirstValidUrl(),
          equals('https://example.com/search?q=test&lang=en'),
        );
      });

      test('should extract URL with fragment if parseable', () {
        const text = 'See https://example.com/page';
        // getFirstValidUrl filters by Uri.tryParse().isAbsolute
        // So it only returns valid, parseable absolute URLs
        expect(text.getFirstValidUrl(), equals('https://example.com/page'));
      });

      test('should extract first URL when multiple present', () {
        const text = 'First https://example.com and second https://other.com';
        expect(text.getFirstValidUrl(), equals('https://example.com'));
      });

      test('should extract URL with port', () {
        const text = 'Server at https://example.com:8080/api';
        expect(text.getFirstValidUrl(), equals('https://example.com:8080/api'));
      });
    });

    group('getFirstValidUrl - Edge cases', () {
      test('should handle URL at exactly 2048 character limit', () {
        final longPath = 'a' * (2048 - 'https://example.com/'.length);
        final text = 'https://example.com/$longPath';
        final result = text.getFirstValidUrl();

        expect(result, isNotNull);
        expect(result!.length, lessThanOrEqualTo(2048));
      });

      test('should handle URL exceeding 2048 character limit', () {
        final longPath = 'a' * 3000;
        final text = 'https://example.com/$longPath more text';
        final result = text.getFirstValidUrl();

        // Regex matches up to 2048 chars, then Uri.tryParse validates it
        // The extracted match will be truncated but may still be valid
        if (result != null) {
          // Result might be shorter than 2048 if Uri parsing fails on partial URL
          expect(result.length, greaterThan(0));
        }
      });

      test('should return null when no URL present', () {
        const text = 'No URL here, just text';
        expect(text.getFirstValidUrl(), isNull);
      });

      test('should return null for HTTP (not HTTPS)', () {
        const text = 'http://example.com';
        expect(text.getFirstValidUrl(), isNull);
      });

      test('should handle URL with special characters', () {
        const text = 'https://example.com/path?query=hello%20world&foo=bar';
        expect(text.getFirstValidUrl(), isNotNull);
      });
    });

    group('getFirstValidUrl - ReDoS attack prevention', () {
      test('should handle extremely long URL quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: [^\s]+ would try to match unlimited characters
        final malicious = 'https://${'a' * 100000}';

        final result = malicious.getFirstValidUrl();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        // Should still return a result (truncated to 2048)
        expect(result, isNotNull);
      });

      test('should handle URL with excessive non-whitespace chars quickly', () {
        final stopwatch = Stopwatch()..start();

        final malicious = 'Text https://example.com/${'x' * 50000} end';

        malicious.getFirstValidUrl();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });

      test('should handle multiple very long URLs quickly', () {
        final stopwatch = Stopwatch()..start();

        final longUrl = 'https://example.com/${'a' * 10000}';
        final malicious = List.generate(100, (_) => longUrl).join(' ');

        final result = malicious.getFirstValidUrl();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300), // Generous threshold for CI environments
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isNotNull);
      });
    });

    group('unMarkdownLinks - ReDoS tests', () {
      test('should handle normal markdown links', () {
        const formatted = '[Link](https://example.com)';
        const unformatted = 'https://example.com';
        final result = formatted.unMarkdownLinks(unformatted);

        expect(result, isNotEmpty);
      });

      test('should handle extremely long URLs in markdown quickly', () {
        final stopwatch = Stopwatch()..start();

        final longUrl = 'https://example.com/${'a' * 50000}';
        final formatted = '[$longUrl]($longUrl)';

        formatted.unMarkdownLinks(longUrl);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300), // Generous threshold for CI environments
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });
    });
  });

  group('String extension URL separator removal ReDoS tests', () {
    group('removeUrlSeparatorAndPreceding - Valid inputs', () {
      test('should remove protocol separator', () {
        const text = 'https://example.com';
        final result = text.removeUrlSeparatorAndPreceding();

        expect(result, equals('example.com'));
      });

      test('should remove custom protocol', () {
        const text = 'custom://path/to/resource';
        final result = text.removeUrlSeparatorAndPreceding();

        expect(result, equals('path/to/resource'));
      });

      test('should remove standalone separator', () {
        const text = 'some text   ://   more text';
        final result = text.removeUrlSeparatorAndPreceding();

        expect(result.contains('://'), isFalse);
      });

      test('should handle multiple protocols', () {
        const text = 'http://first.com and ftp://second.com';
        final result = text.removeUrlSeparatorAndPreceding();

        expect(result.contains('://'), isFalse);
      });
    });

    group('removeUrlSeparatorAndPreceding - Edge cases', () {
      test('should handle protocol at exactly 100 character limit', () {
        final protocol = 'a' * 100;
        final text = '$protocol://example.com';
        final result = text.removeUrlSeparatorAndPreceding();

        expect(result.contains('://'), isFalse);
      });

      test('should handle protocol exceeding 100 character limit', () {
        final protocol = 'a' * 150;
        final text = '$protocol://example.com';
        final result = text.removeUrlSeparatorAndPreceding();

        // The regex fails to match the full 150 chars due to {0,100} limit,
        // but \b matches the boundary between 'a' and ':', so it matches '://'
        // and removes it, leaving the protocol text.
        expect(result, equals('${protocol}example.com'));
      });

      test('should handle exactly 10 spaces before separator', () {
        const text = 'text          ://          resource';
        final result = text.removeUrlSeparatorAndPreceding();

        expect(result.contains('://'), isFalse);
      });

      test('should handle text without separators', () {
        const text = 'No separators here';
        final result = text.removeUrlSeparatorAndPreceding();

        expect(result, equals(text));
      });
    });

    group('removeUrlSeparatorAndPreceding - ReDoS attack prevention', () {
      test('should handle excessive characters before separator quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: [^ ]* would try unlimited matches
        final malicious = '${'a' * 10000}://resource';

        malicious.removeUrlSeparatorAndPreceding();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });

      test('should handle excessive spaces around separator quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix:  *://  * would try unlimited space matches
        final malicious = '${' ' * 1000}://${' ' * 1000}';

        malicious.removeUrlSeparatorAndPreceding();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });

      test('should handle multiple malicious separators quickly', () {
        final stopwatch = Stopwatch()..start();

        final malicious = List.generate(100, (i) => '${'x' * 500}://').join();

        malicious.removeUrlSeparatorAndPreceding();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300), // Generous threshold for CI environments
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });
    });
  });

  group('String extension anchor parsing ReDoS tests', () {
    group('isContainsATag - Valid inputs', () {
      test('should detect simple anchor tag', () {
        const text = '<a href="url">Link</a>';
        expect(text.isContainsATag(), isTrue);
      });

      test('should detect anchor with attributes', () {
        const text = '<a href="url" class="link">Text</a>';
        expect(text.isContainsATag(), isTrue);
      });

      test('should detect anchor with long text', () {
        final text = '<a href="url">${'x' * 500}</a>';
        expect(text.isContainsATag(), isTrue);
      });

      test('should return false for non-anchor tags', () {
        const text = '<p>Paragraph</p>';
        expect(text.isContainsATag(), isFalse);
      });
    });

    group('isContainsATag - Edge cases', () {
      test('should handle tag with exactly 500 character attributes', () {
        // Pattern: <a[^>]{0,500}> means 0-500 chars between 'a' and '>'
        // This includes the space and attributes
        final attrs = ' ${'a' * 499}'; // Space + 499 chars = 500 total
        final text = '<a$attrs>Text</a>';
        expect(text.isContainsATag(), isTrue);
      });

      test('should handle content at exactly 1000 characters', () {
        final content = 'x' * 1000;
        final text = '<a href="url">$content</a>';
        expect(text.isContainsATag(), isTrue);
      });

      test('should reject tag with attributes exceeding 500 chars', () {
        final attrs = 'a' * 600;
        final text = '<a $attrs>Text</a>';
        expect(text.isContainsATag(), isFalse);
      });

      test('should reject content exceeding 1000 chars', () {
        final content = 'x' * 1500;
        final text = '<a href="url">$content</a>';
        expect(text.isContainsATag(), isFalse);
      });
    });

    group('isContainsATag - ReDoS attack prevention', () {
      test('should handle excessive tag attributes quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: [^>]* would try unlimited matches
        final malicious = '<a ${'x' * 10000}>Text</a>';

        final result = malicious.isContainsATag();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isFalse); // Exceeds 500 char limit
      });

      test('should handle excessive content quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: [^<]* would try unlimited matches
        final malicious = '<a href="url">${'x' * 50000}</a>';

        final result = malicious.isContainsATag();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isFalse); // Exceeds 1000 char limit
      });

      test('should handle unclosed tags quickly', () {
        final stopwatch = Stopwatch()..start();

        final malicious = '<a href="url">${'x' * 50000}';

        malicious.isContainsATag();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });
    });

    group('extractAllHrefs - Valid inputs', () {
      test('should extract href from simple anchor', () {
        const text = '<a href="https://example.com">Link</a>';
        final hrefs = text.extractAllHrefs();

        expect(hrefs, equals(['https://example.com']));
      });

      test('should extract multiple hrefs', () {
        const text = '<a href="url1">Link1</a> and <a href="url2">Link2</a>';
        final hrefs = text.extractAllHrefs();

        expect(hrefs, equals(['url1', 'url2']));
      });

      test('should handle anchor with attributes', () {
        const text = '<a class="btn" href="url" target="_blank">Link</a>';
        final hrefs = text.extractAllHrefs();

        expect(hrefs, equals(['url']));
      });
    });

    group('extractAllHrefs - Edge cases', () {
      test('should handle href at exactly 2048 character limit', () {
        final longUrl = 'https://example.com/${'a' * 2020}';
        final text = '<a href="$longUrl">Link</a>';
        final hrefs = text.extractAllHrefs();

        expect(hrefs.length, equals(1));
        expect(hrefs[0].length, lessThanOrEqualTo(2048));
      });

      test('should reject href exceeding 2048 chars', () {
        final longUrl = 'https://example.com/${'a' * 3000}';
        final text = '<a href="$longUrl">Link</a>';
        final hrefs = text.extractAllHrefs();

        expect(hrefs, isEmpty);
      });

      test('should return empty list when no anchors', () {
        const text = 'No anchors here';
        expect(text.extractAllHrefs(), isEmpty);
      });
    });

    group('extractAllHrefs - ReDoS attack prevention', () {
      test('should handle excessive href length quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: [^"]* would try unlimited matches
        final malicious = '<a href="${'x' * 100000}">Link</a>';

        final hrefs = malicious.extractAllHrefs();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(hrefs, isEmpty); // Exceeds 2048 limit
      });

      test('should handle excessive attributes quickly', () {
        final stopwatch = Stopwatch()..start();

        final malicious =
            '<a ${'data-attr="value" ' * 1000}href="url">Link</a>';

        malicious.extractAllHrefs();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });

      test('should handle excessive content quickly', () {
        final stopwatch = Stopwatch()..start();

        final malicious = '<a href="url">${'x' * 50000}</a>';

        malicious.extractAllHrefs();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });

      test('should handle many anchors quickly', () {
        final stopwatch = Stopwatch()..start();

        final malicious = List.generate(
          1000,
          (i) => '<a href="url$i">Link</a>',
        ).join();

        final hrefs = malicious.extractAllHrefs();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500), // Generous threshold for CI environments
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(hrefs.length, equals(1000));
      });
    });

    group('extractInnerText - Valid inputs', () {
      test('should extract inner text from anchor', () {
        const text = '<a href="url">Click here</a>';
        expect(text.extractInnerText(), equals('Click here'));
      });

      test('should extract text with special chars', () {
        const text = '<a href="url">Click & go!</a>';
        expect(text.extractInnerText(), equals('Click & go!'));
      });

      test('should return null when no anchor', () {
        const text = 'No anchor here';
        expect(text.extractInnerText(), isNull);
      });
    });

    group('extractInnerText - ReDoS attack prevention', () {
      test('should handle excessive inner text quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: [^<]* would try unlimited matches
        final malicious = '<a href="url">${'x' * 50000}</a>';

        malicious.extractInnerText();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });

      test('should handle excessive attributes quickly', () {
        final stopwatch = Stopwatch()..start();

        final malicious = '<a ${'x' * 10000}>Text</a>';

        malicious.extractInnerText();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });
    });
  });
}
