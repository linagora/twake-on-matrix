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

    test('keeps the formatting carried by linkStyle', () {
      // The formatting is only kept when it reaches linkStyle: the app's own
      // link style can still override it (e.g. bold) before linkBuilder runs.
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

    test('keeps an inline widget inside a filename anchor', () {
      // e.g. <a href="report.md"><img src="mxc://..."></a>
      const image = WidgetSpan(child: SizedBox(key: Key('anchor-image')));
      final span = host.filenameLinkAsPlainText(
        url: 'report.md',
        childrenSpan: const TextSpan(
          children: [
            image,
            TextSpan(text: 'report', style: linkStyle),
          ],
        ),
        linkStyle: linkStyle,
        textStyle: textStyle,
      );

      final widgets = <WidgetSpan>[];
      span!.visitChildren((child) {
        if (child is WidgetSpan) widgets.add(child);
        return true;
      });
      expect(widgets, [image]);
    });

    test('keeps nested formatting inside a filename anchor', () {
      // e.g. <a href="report.md"><b>my</b> report</a>
      final span = host.filenameLinkAsPlainText(
        url: 'report.md',
        childrenSpan: TextSpan(
          children: [
            TextSpan(
              text: 'my',
              style: linkStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' report', style: linkStyle),
          ],
        ),
        linkStyle: linkStyle,
        textStyle: textStyle,
      );

      final texts = <TextSpan>[];
      span!.visitChildren((child) {
        if (child is TextSpan && child.text != null) texts.add(child);
        return true;
      });
      expect(texts.map((text) => text.text), ['my', ' report']);
      expect(texts.first.style?.fontWeight, FontWeight.bold);
      for (final text in texts) {
        expect(text.style?.color, textStyle.color);
        expect(text.style?.decoration, TextDecoration.none);
      }
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
