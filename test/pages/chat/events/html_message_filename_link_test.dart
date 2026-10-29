import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/events/html_message.dart';

void main() {
  const textStyle = TextStyle(color: Colors.black);
  const linkStyle = TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );

  TextSpan? build(String url) => filenameLinkAsPlainText(
    url: url,
    childrenSpan: TextSpan(text: url, style: linkStyle),
    textStyle: textStyle,
  );

  group('filenameLinkAsPlainText', () {
    test('renders a filename as plain text', () {
      final span = build('test.md');
      expect(span, isNotNull);
      expect(span!.toPlainText(), 'test.md');
      expect(span.style, textStyle);
      expect(span.recognizer, isNull);
    });

    test('renders a multi-dot filename as plain text', () {
      expect(build('archive.tar.gz')?.toPlainText(), 'archive.tar.gz');
    });

    test('keeps the anchor text of a filename href', () {
      final span = filenameLinkAsPlainText(
        url: 'report.pdf',
        childrenSpan: const TextSpan(text: 'my report', style: linkStyle),
        textStyle: textStyle,
      );
      expect(span?.toPlainText(), 'my report');
      expect(span?.style, textStyle);
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
