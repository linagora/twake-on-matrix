import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/string_extension.dart';

/// ReDoS unit tests for HTML mx-reply tag removal regex
/// Reference: ADR 0033 - Fix ReDoS vulnerabilities in regex patterns
/// Covers String.removeReplyFallback, used by HtmlMessage
void main() {
  group('HTML mx-reply tag removal ReDoS tests', () {
    String removeMxReplyTags(String html) => html.removeReplyFallback();

    group('Valid mx-reply tag removal', () {
      test('should remove simple mx-reply tag', () {
        const html = '<mx-reply>Reply content</mx-reply>';
        final result = removeMxReplyTags(html);
        expect(result, isEmpty);
      });

      test('should remove mx-reply with nested content', () {
        const html = '<mx-reply><p>Some reply text</p></mx-reply>';
        final result = removeMxReplyTags(html);
        expect(result, isEmpty);
      });

      test('should preserve content outside mx-reply tags', () {
        const html = '<p>Before</p><mx-reply>Reply</mx-reply><p>After</p>';
        final result = removeMxReplyTags(html);
        expect(result, equals('<p>Before</p><p>After</p>'));
      });

      test('should remove multiple mx-reply tags', () {
        const html =
            '<mx-reply>First</mx-reply><p>Content</p><mx-reply>Second</mx-reply>';
        final result = removeMxReplyTags(html);
        expect(result, equals('<p>Content</p>'));
      });

      test('should handle case-insensitive tags', () {
        const html = '<MX-REPLY>Reply</MX-REPLY>';
        final result = removeMxReplyTags(html);
        expect(result, isEmpty);
      });

      test('should handle mixed case tags', () {
        const html = '<Mx-Reply>Reply</mx-REPLY>';
        final result = removeMxReplyTags(html);
        expect(result, isEmpty);
      });

      test('should remove mx-reply with line breaks', () {
        const html = '''<mx-reply>
          <p>Multi-line</p>
          <p>Reply content</p>
        </mx-reply>''';
        final result = removeMxReplyTags(html);
        expect(result.trim(), isEmpty);
      });

      test('should handle mx-reply with attributes', () {
        const html = '<mx-reply class="reply">Content</mx-reply>';
        final result = removeMxReplyTags(html);
        // Note: The regex looks for <mx-reply> not <mx-reply ...>
        // so attributes would prevent matching
        // This test documents current behavior
        expect(result, equals(html));
      });
    });

    group('Edge cases', () {
      test('should handle empty mx-reply tag', () {
        const html = '<mx-reply></mx-reply>';
        final result = removeMxReplyTags(html);
        expect(result, isEmpty);
      });

      test('should handle self-closing tag (not matched)', () {
        const html = '<mx-reply/>';
        final result = removeMxReplyTags(html);
        // Self-closing tags don't match the pattern
        expect(result, equals(html));
      });

      test('should handle mismatched tags gracefully', () {
        const html = '<mx-reply>Content</mx-other>';
        final result = removeMxReplyTags(html);
        // Non-matching closing tag means no match
        expect(result, equals(html));
      });

      test('should remove the whole outer block when mx-reply is nested', () {
        const html =
            '<mx-reply>Outer <mx-reply>Inner</mx-reply> Outer</mx-reply>Reply';
        expect(removeMxReplyTags(html), equals('Reply'));
      });

      test('should strip a nested reply fallback sent by iamb (#3237)', () {
        const html =
            '<mx-reply><blockquote>'
            '<a href="https://matrix.to/#/!room/\$b">In reply to</a> '
            '<a href="https://matrix.to/#/@bob:localhost">@bob:localhost</a><br>'
            '<mx-reply><blockquote>'
            '<a href="https://matrix.to/#/!room/\$a">In reply to</a> '
            '<a href="https://matrix.to/#/@alice:localhost">@alice:localhost</a><br>'
            'First message'
            '</blockquote></mx-reply>'
            'Second message'
            '</blockquote></mx-reply>'
            'My answer';
        expect(removeMxReplyTags(html), equals('My answer'));
      });

      test('should keep content between two nested reply blocks', () {
        const html =
            '<mx-reply>A<mx-reply>B</mx-reply></mx-reply>Middle'
            '<mx-reply>C</mx-reply>End';
        expect(removeMxReplyTags(html), equals('MiddleEnd'));
      });

      test('should strip up to the last closing tag when the outer block is '
          'never closed', () {
        const html = '<mx-reply>A<mx-reply>B</mx-reply>C';
        expect(removeMxReplyTags(html), equals('C'));
      });

      test('should ignore a stray closing tag', () {
        const html = 'Before</mx-reply><mx-reply>Reply</mx-reply>After';
        expect(removeMxReplyTags(html), equals('Before</mx-reply>After'));
      });

      test('should handle very long content inside mx-reply', () {
        final longContent = 'x' * 10000;
        final html = '<mx-reply>$longContent</mx-reply>';
        final result = removeMxReplyTags(html);
        expect(result, isEmpty);
      });
    });

    group('ReDoS attack prevention', () {
      test('should handle malicious input with excessive content quickly', () {
        final stopwatch = Stopwatch()..start();

        // Before fix: greedy .* would try all possible matches
        // causing catastrophic backtracking with multiple tags
        final malicious =
            '<mx-reply>${'a' * 10000}</mx-reply>${'b' * 10000}<mx-reply>';

        final result = removeMxReplyTags(malicious);
        stopwatch.stop();

        // Should complete in milliseconds, not seconds
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        // Verify it still works correctly
        expect(result.contains('<mx-reply>'), isTrue); // Unclosed tag remains
      });

      test('should handle deeply nested HTML quickly', () {
        final stopwatch = Stopwatch()..start();

        // Create deeply nested HTML that could cause backtracking
        final nested = '${'<p>' * 1000}content${'</p>' * 1000}';
        final malicious = '<mx-reply>$nested</mx-reply>';

        final result = removeMxReplyTags(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isEmpty);
      });

      test('should handle multiple unclosed tags quickly', () {
        final stopwatch = Stopwatch()..start();

        // Multiple opening tags without proper closing
        // Before fix: would try many combinations
        final malicious = ('<mx-reply>' * 100) + ('content' * 100);

        removeMxReplyTags(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });

      test('should handle alternating tags and content quickly', () {
        final stopwatch = Stopwatch()..start();

        // Alternating pattern that could cause backtracking
        final malicious = ('<mx-reply>content</mx-reply>' * 1000);

        final result = removeMxReplyTags(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isEmpty);
      });

      test(
        'should handle malicious pattern with no closing tag and very long content',
        () {
          final stopwatch = Stopwatch()..start();

          // Before fix: greedy .* would consume everything then backtrack
          final malicious = '<mx-reply>${'x' * 100000}<mx-reply>';

          removeMxReplyTags(malicious);
          stopwatch.stop();

          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(200),
            reason: 'ReDoS vulnerability: excessive backtracking detected',
          );
        },
      );

      test('should handle complex HTML with special characters quickly', () {
        final stopwatch = Stopwatch()..start();

        // HTML with many special chars that could affect matching
        final specialChars = r'<>&"\n\t\r' * 5000;
        final malicious = '<mx-reply>$specialChars</mx-reply>';

        final result = removeMxReplyTags(malicious);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );

        expect(result, isEmpty);
      });
    });

    group('Non-greedy vs greedy behavior', () {
      test('demonstrates non-greedy .*? stops at first closing tag', () {
        const html =
            '<mx-reply>First</mx-reply>Middle<mx-reply>Second</mx-reply>';
        final result = removeMxReplyTags(html);

        // Non-greedy .*? matches minimally, so both tags are removed separately
        expect(result, equals('Middle'));
      });

      test('demonstrates greedy .* would be problematic (documentation)', () {
        // This test documents why greedy was a problem
        // With greedy .*: <mx-reply>First</mx-reply>Middle<mx-reply>Second</mx-reply>
        // Would try to match from first <mx-reply> to LAST </mx-reply>
        // consuming the entire string, then backtracking

        // With non-greedy .*?: matches from first <mx-reply> to FIRST </mx-reply>
        // This is much more efficient

        const html =
            '<mx-reply>A</mx-reply><mx-reply>B</mx-reply><mx-reply>C</mx-reply>';
        final result = removeMxReplyTags(html);

        expect(result, isEmpty);
      });
    });
  });
}
