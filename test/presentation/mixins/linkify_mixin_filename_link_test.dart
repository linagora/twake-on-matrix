import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/presentation/mixins/linkify_mixin.dart';

class _LinkifyHost with LinkifyMixin {}

void main() {
  final host = _LinkifyHost();
  const textStyle = TextStyle(color: Colors.black);
  const linkStyle = TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );

  TextSpan? build(String url) => host.filenameLinkAsPlainText(
    url: url,
    childrenSpan: TextSpan(text: url, style: linkStyle),
    linkStyle: linkStyle,
    textStyle: textStyle,
  );

  group('filenameLinkAsPlainText', () {
    test('renders a filename as plain text', () {
      final span = build('test.md');
      expect(span, isNotNull);
      expect(span!.toPlainText(), 'test.md');
      expect(span.style?.color, textStyle.color);
      expect(span.style?.decoration, TextDecoration.none);
      expect(span.recognizer, isNull);
    });

    test('renders a multi-dot filename as plain text', () {
      expect(build('archive.tar.gz')?.toPlainText(), 'archive.tar.gz');
    });

    test('keeps the anchor text of a filename href', () {
      final span = host.filenameLinkAsPlainText(
        url: 'report.pdf',
        childrenSpan: const TextSpan(text: 'my report', style: linkStyle),
        linkStyle: linkStyle,
        textStyle: textStyle,
      );
      expect(span?.toPlainText(), 'my report');
      expect(span?.style?.color, textStyle.color);
    });

    test('keeps the inherited formatting of a filename', () {
      // e.g. **test.md**: the parent bold/italic is merged into linkStyle.
      final span = host.filenameLinkAsPlainText(
        url: 'test.md',
        childrenSpan: const TextSpan(text: 'test.md'),
        linkStyle: linkStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
        textStyle: textStyle,
      );
      expect(span?.style?.fontWeight, FontWeight.bold);
      expect(span?.style?.fontStyle, FontStyle.italic);
      expect(span?.style?.color, textStyle.color);
      expect(span?.style?.decoration, TextDecoration.none);
    });

    test('keeps a www. link as a link', () {
      expect(build('www.test.md'), isNull);
    });

    test('keeps an https link as a link', () {
      expect(build('https://test.md'), isNull);
      expect(build('https://example.com'), isNull);
    });

    test('keeps a link with a path as a link', () {
      expect(build('example.com/test.md'), isNull);
    });

    test('keeps a regular domain as a link', () {
      expect(build('example.com'), isNull);
    });
  });
}
