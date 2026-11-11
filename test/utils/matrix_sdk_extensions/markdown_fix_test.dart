import 'package:twake_chat/utils/matrix_sdk_extensions/markdown_fix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fixDoubleEncodedCodeBlocks', () {
    test('decodes double-encoded angle brackets in fenced code block', () {
      const input =
          '<pre><code class="language-dart">&amp;lt;&amp;gt;\n</code></pre>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(
        result,
        '<pre><code class="language-dart">&lt;&gt;\n</code></pre>',
      );
    });

    test('decodes double-encoded generics in inline code', () {
      const input = '<code>&amp;lt;String&amp;gt;</code>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, '<code>&lt;String&gt;</code>');
    });

    test('decodes List<String> in code block', () {
      const input =
          '<pre><code class="language-dart">List&amp;lt;String&amp;gt; items = [];\n</code></pre>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(
        result,
        '<pre><code class="language-dart">List&lt;String&gt; items = [];\n</code></pre>',
      );
    });

    test('decodes nested generics Map<String, List<int>>', () {
      const input =
          '<pre><code>Map&amp;lt;String, List&amp;lt;int&amp;gt;&amp;gt;</code></pre>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(
        result,
        '<pre><code>Map&lt;String, List&lt;int&gt;&gt;</code></pre>',
      );
    });

    test('does not modify content outside code tags', () {
      const input = '<p>&amp;lt;div&amp;gt;hello&amp;lt;/div&amp;gt;</p>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, input);
    });

    test('does not modify plain text in code tags', () {
      const input = '<code>hello world</code>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, input);
    });

    test(
      'does not modify already-correct single-encoded HTML in code tags',
      () {
        const input = '<code>List&lt;String&gt;</code>';
        final result = fixDoubleEncodedCodeBlocks(input);
        expect(result, input);
      },
    );

    test('handles mixed content with code and non-code', () {
      const input =
          '<p>See this: <code>&amp;lt;T&amp;gt;</code> in &amp;lt;div&amp;gt;</p>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(
        result,
        '<p>See this: <code>&lt;T&gt;</code> in &amp;lt;div&amp;gt;</p>',
      );
    });

    test('handles multiple code blocks', () {
      const input =
          '<code>&amp;lt;A&amp;gt;</code> text <code>&amp;lt;B&amp;gt;</code>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, '<code>&lt;A&gt;</code> text <code>&lt;B&gt;</code>');
    });

    test('handles &amp;amp; entity in code block', () {
      const input = '<code>a &amp;amp; b</code>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, '<code>a &amp; b</code>');
    });

    test('returns input unchanged when no code tags present', () {
      const input = '<p>just some text</p>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, input);
    });

    test('handles empty code tag', () {
      const input = '<code></code>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, input);
    });

    test('handles code tag with language class and multiline', () {
      const input =
          '<pre><code class="language-dart">void main() {\n'
          '  final list = &amp;lt;String&amp;gt;[];\n'
          '  print(list);\n'
          '}</code></pre>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(
        result,
        '<pre><code class="language-dart">void main() {\n'
        '  final list = &lt;String&gt;[];\n'
        '  print(list);\n'
        '}</code></pre>',
      );
    });
  });

  group('fixDoubleEncodedAutolinks', () {
    // Inputs are the exact output of package:markdown 7.3.1 for bare URLs
    // (GitHub-flavored autolinks), which re-encode an existing `%XX`.
    test('restores the single encoding of a message link', () {
      const input =
          '<a href="https://matrix.to/#/!r%253Aex.org/%2524e">'
          'https://matrix.to/#/!r%3Aex.org/%24e</a>';

      expect(
        fixDoubleEncodedAutolinks(input),
        '<a href="https://matrix.to/#/!r%3Aex.org/%24e">'
        'https://matrix.to/#/!r%3Aex.org/%24e</a>',
      );
    });

    test('keeps the HTML escaping of & in the query', () {
      const input =
          '<p>see <a href="https://a.org/x?y=1&amp;z=%253A">'
          'https://a.org/x?y=1&amp;z=%3A</a> end</p>';

      expect(
        fixDoubleEncodedAutolinks(input),
        '<p>see <a href="https://a.org/x?y=1&amp;z=%3A">'
        'https://a.org/x?y=1&amp;z=%3A</a> end</p>',
      );
    });

    test('restores a www. link, which markdown prefixes with http://', () {
      const input = '<a href="http://www.a.org/%253A">www.a.org/%3A</a>';

      expect(
        fixDoubleEncodedAutolinks(input),
        '<a href="http://www.a.org/%3A">www.a.org/%3A</a>',
      );
    });

    test('still encodes a raw % that starts no escape', () {
      const input = '<a href="https://a.org/50%25off">https://a.org/50%off</a>';

      expect(fixDoubleEncodedAutolinks(input), input);
    });

    test('leaves a link whose text differs from its href', () {
      const input = '<a href="https://example.org/a%253Ab">label</a>';

      expect(fixDoubleEncodedAutolinks(input), input);
    });

    test('leaves a correctly encoded link from another client', () {
      const input =
          '<a href="https://matrix.to/#/!r%3Aex.org/%24e">'
          'https://matrix.to/#/!r%3Aex.org/%24e</a>';

      expect(fixDoubleEncodedAutolinks(input), input);
    });

    test('leaves an anchor whose text is past the bounded length', () {
      final text = 'https://example.org/${'a' * 1000}%3A';
      final input = '<a href="${Uri.encodeFull(text)}">$text</a>';

      expect(fixDoubleEncodedAutolinks(input), input);
    });
  });
}
