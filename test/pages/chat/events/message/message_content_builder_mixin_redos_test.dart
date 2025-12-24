import 'package:flutter_test/flutter_test.dart';

/// ReDoS unit tests for special HTML tag detection regex
/// Reference: ADR 0033 - Fix ReDoS vulnerabilities in regex patterns
/// Vulnerability: lib/pages/chat/events/message/message_content_builder_mixin.dart:368
/// Before: [^>]*>.*</ (unbounded attributes, greedy content matching)
/// After: [^>]{0,500}>.*?</ (bounded attributes, non-greedy content matching)
void main() {
  group('Special HTML tag detection ReDoS tests', () {
    // The actual regex pattern used in isContainsSpecialHTMLTag
    final specialTags = [
      'b',
      'strong',
      'tt',
      'h[1-6]',
      'code',
      'pre',
      'blockquote',
      'i',
      'em',
    ];
    final specialTagsPattern = specialTags.join('|');
    final specialTagRegex = RegExp(
      '<($specialTagsPattern)[^>]{0,500}>.*?</($specialTagsPattern)>|<hr[^>]{0,500}>',
      multiLine: true,
      dotAll: true,
    );

    bool containsSpecialTag(String html) {
      return specialTagRegex.hasMatch(html);
    }

    group('Valid special tag detection', () {
      test('should detect bold tag', () {
        expect(containsSpecialTag('<b>Bold text</b>'), isTrue);
      });

      test('should detect strong tag', () {
        expect(containsSpecialTag('<strong>Strong text</strong>'), isTrue);
      });

      test('should detect italic tag', () {
        expect(containsSpecialTag('<i>Italic text</i>'), isTrue);
      });

      test('should detect em tag', () {
        expect(containsSpecialTag('<em>Emphasized text</em>'), isTrue);
      });

      test('should detect code tag', () {
        expect(containsSpecialTag('<code>console.log("test")</code>'), isTrue);
      });

      test('should detect pre tag', () {
        expect(containsSpecialTag('<pre>Preformatted\ntext</pre>'), isTrue);
      });

      test('should detect blockquote tag', () {
        expect(
          containsSpecialTag('<blockquote>Quoted text</blockquote>'),
          isTrue,
        );
      });

      test('should detect tt tag', () {
        expect(containsSpecialTag('<tt>Teletype text</tt>'), isTrue);
      });

      test('should detect heading tags h1-h6', () {
        expect(containsSpecialTag('<h1>Heading 1</h1>'), isTrue);
        expect(containsSpecialTag('<h2>Heading 2</h2>'), isTrue);
        expect(containsSpecialTag('<h3>Heading 3</h3>'), isTrue);
        expect(containsSpecialTag('<h4>Heading 4</h4>'), isTrue);
        expect(containsSpecialTag('<h5>Heading 5</h5>'), isTrue);
        expect(containsSpecialTag('<h6>Heading 6</h6>'), isTrue);
      });

      test('should detect hr tag', () {
        expect(containsSpecialTag('<hr>'), isTrue);
        // Note: <hr/> has '/' as a [^>] char, so it matches the pattern
        expect(containsSpecialTag('<hr/>'), isTrue);
      });

      test('should detect tag with attributes', () {
        expect(containsSpecialTag('<b class="highlight">Bold</b>'), isTrue);
      });

      test('should detect tag with multiple attributes', () {
        expect(
          containsSpecialTag(
            '<strong class="important" id="main">Strong</strong>',
          ),
          isTrue,
        );
      });

      test('should detect tag in larger HTML content', () {
        const html = '<p>Normal text</p><b>Bold text</b><p>More text</p>';
        expect(containsSpecialTag(html), isTrue);
      });

      test('should detect nested content', () {
        expect(
          containsSpecialTag('<b>Bold <i>and italic</i> text</b>'),
          isTrue,
        );
      });
    });

    group('Invalid or non-special tags', () {
      test('should not detect paragraph tag', () {
        expect(containsSpecialTag('<p>Paragraph</p>'), isFalse);
      });

      test('should not detect div tag', () {
        expect(containsSpecialTag('<div>Division</div>'), isFalse);
      });

      test('should not detect span tag', () {
        expect(containsSpecialTag('<span>Span</span>'), isFalse);
      });

      test('should not detect anchor tag', () {
        expect(containsSpecialTag('<a href="url">Link</a>'), isFalse);
      });

      test('should not detect plain text', () {
        expect(containsSpecialTag('Plain text without tags'), isFalse);
      });

      test('should not detect unclosed tag', () {
        expect(containsSpecialTag('<b>Unclosed bold'), isFalse);
      });

      test('should detect any special tags even if mismatched', () {
        // Pattern allows <b>.*?</b> OR <i>.*?</i>
        // '<b>Text</i>' contains '<i></i>' which matches
        expect(containsSpecialTag('<b>Text</i>'), isTrue);
      });
    });

    group('Edge cases within limits', () {
      test('should handle tag with exactly 500 character attributes', () {
        // Pattern: <b[^>]{0,500}> means 0-500 chars between 'b' and '>'
        final attrs = ' ${'a' * 499}'; // Space + 499 chars = 500 total
        final html = '<b$attrs>Text</b>';
        expect(containsSpecialTag(html), isTrue);
      });

      test('should reject tag with attributes exceeding 500 chars', () {
        final attrs = 'a' * 600;
        final html = '<b $attrs>Text</b>';
        expect(containsSpecialTag(html), isFalse);
      });

      test('should handle very long content', () {
        final content = 'x' * 10000;
        final html = '<b>$content</b>';
        expect(containsSpecialTag(html), isTrue);
      });

      test('should handle multiline content', () {
        const html = '''<pre>
          Line 1
          Line 2
          Line 3
        </pre>''';
        expect(containsSpecialTag(html), isTrue);
      });

      test('should handle hr with attributes at limit', () {
        // Pattern: <hr[^>]{0,500}> means 0-500 chars between 'hr' and '>'
        final attrs = ' ${'a' * 499}'; // Space + 499 chars = 500 total
        final html = '<hr$attrs>';
        expect(containsSpecialTag(html), isTrue);
      });

      test('should reject hr with excessive attributes', () {
        final attrs = 'a' * 600;
        final html = '<hr $attrs>';
        expect(containsSpecialTag(html), isFalse);
      });
    });

    group('ReDoS attack prevention', () {
      test('should handle excessive tag attributes quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: [^>]* would try unlimited matches
        final malicious = '<b ${'x' * 10000}>Text</b>';

        final result = containsSpecialTag(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isFalse); // Exceeds 500 char attribute limit
      });

      test('should handle excessive content quickly (non-greedy test)', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: greedy .* would consume everything then backtrack
        final malicious = '<b>${'x' * 100000}</b>';

        final result = containsSpecialTag(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isTrue); // Non-greedy .*? is efficient
      });

      test('should handle nested tags with excessive content quickly', () {
        final stopwatch = Stopwatch()..start();

        final nested = '${'<p>' * 1000}content${'</p>' * 1000}';
        final malicious = '<b>$nested</b>';

        final result = containsSpecialTag(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isTrue);
      });

      test('should handle multiple tags with excessive attributes quickly', () {
        final stopwatch = Stopwatch()..start();

        final malicious = List.generate(
          100,
          (i) => '<b ${'x' * 1000}>Text$i</b>',
        ).join();

        containsSpecialTag(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });

      test(
        'should handle alternating valid/invalid pattern quickly (backtracking)',
        () {
          final stopwatch = Stopwatch()..start();

          // Create pattern that could cause backtracking:
          // Multiple opening tags with no proper closing
          final malicious = ('<b>' * 1000) + ('text' * 1000);

          containsSpecialTag(malicious);
          stopwatch.stop();

          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(200),
            reason: 'ReDoS vulnerability: excessive backtracking detected',
          );
        },
      );

      test('should handle greedy vs non-greedy scenario quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: greedy .* in <b>.*</b> would match from first <b> to LAST </b>
        // causing massive backtracking with multiple tags
        final malicious = '<b>First</b>${'x' * 50000}<b>Last</b>';

        final result = containsSpecialTag(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isTrue);
      });

      test('should handle unclosed tags with excessive content quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: greedy .* would consume everything looking for closing tag
        final malicious = '<b>${'x' * 100000}';

        final result = containsSpecialTag(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isFalse); // No closing tag
      });

      test('should handle hr tags with excessive attributes quickly', () {
        final stopwatch = Stopwatch()..start();

        final malicious = '<hr ${'x' * 10000}>';

        final result = containsSpecialTag(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isFalse); // Exceeds 500 char limit
      });

      test('should handle complex mixed content quickly', () {
        final stopwatch = Stopwatch()..start();

        // Mix of valid and invalid patterns
        final malicious =
            '<b>Valid</b>${'<p>' * 1000}<strong ${'x' * 2000}>Text</strong>${'<i>Italic</i>' * 500}';

        final result = containsSpecialTag(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isTrue); // Contains valid <b> and <i> tags
      });
    });

    group('Non-greedy behavior validation', () {
      test('demonstrates non-greedy .*? matches minimally', () {
        const html = '<b>First</b>Middle<b>Second</b>';
        expect(containsSpecialTag(html), isTrue);

        // Non-greedy .*? in <b>.*?</b> matches:
        // 1st match: <b>First</b>
        // 2nd match: <b>Second</b>
        // Does NOT match from first <b> to last </b>
      });

      test('demonstrates greedy would be problematic', () {
        // This test documents why greedy .* was a problem
        const html = '<b>A</b><b>B</b><b>C</b>';

        // With greedy .*: <b>.*</b> would try to match from
        // first <b> to LAST </b>, consuming entire string

        // With non-greedy .*?: matches each tag pair separately
        expect(containsSpecialTag(html), isTrue);
      });
    });
  });
}
