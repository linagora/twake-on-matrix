import 'package:fluffychat/utils/matrix_sdk_extensions/markdown_fix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fixDoubleEncodedCodeBlocks', () {
    test('decodes double-encoded angle brackets in fenced code block', () {
      const input = '<pre><code class="language-dart">&amp;lt;&amp;gt;\n</code></pre>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, '<pre><code class="language-dart"><>\n</code></pre>');
    });

    test('decodes double-encoded generics in inline code', () {
      const input = '<code>&amp;lt;String&amp;gt;</code>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, '<code><String></code>');
    });

    test('decodes List<String> in code block', () {
      const input =
          '<pre><code class="language-dart">List&amp;lt;String&amp;gt; items = [];\n</code></pre>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(
        result,
        '<pre><code class="language-dart">List<String> items = [];\n</code></pre>',
      );
    });

    test('decodes nested generics Map<String, List<int>>', () {
      const input =
          '<pre><code>Map&amp;lt;String, List&amp;lt;int&amp;gt;&amp;gt;</code></pre>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(
        result,
        '<pre><code>Map<String, List<int>></code></pre>',
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

    test('handles already-correct HTML in code tags', () {
      const input = '<code>List&lt;String&gt;</code>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, '<code>List<String></code>');
    });

    test('handles mixed content with code and non-code', () {
      const input =
          '<p>See this: <code>&amp;lt;T&amp;gt;</code> in &amp;lt;div&amp;gt;</p>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(
        result,
        '<p>See this: <code><T></code> in &amp;lt;div&amp;gt;</p>',
      );
    });

    test('handles multiple code blocks', () {
      const input =
          '<code>&amp;lt;A&amp;gt;</code> text <code>&amp;lt;B&amp;gt;</code>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, '<code><A></code> text <code><B></code>');
    });

    test('handles &amp;amp; entity in code block', () {
      const input = '<code>a &amp;amp; b</code>';
      final result = fixDoubleEncodedCodeBlocks(input);
      expect(result, '<code>a & b</code>');
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
        '  final list = <String>[];\n'
        '  print(list);\n'
        '}</code></pre>',
      );
    });
  });
}
