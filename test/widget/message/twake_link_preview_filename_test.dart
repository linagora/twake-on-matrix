import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/widgets/twake_components/twake_preview_link/twake_link_preview.dart';

import '../../fake_client.dart';

class _TwakeLinkPreviewHarness {
  static const linkStyle = TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );
  static const richTextStyle = TextStyle(color: Colors.black);

  final Room room;

  _TwakeLinkPreviewHarness(this.room);

  Event _textEvent(String body) => Event(
    content: {'body': body, 'msgtype': 'm.text'},
    type: 'm.room.message',
    eventId: '\$event:example.org',
    senderId: '@example:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
    room: room,
  );

  Future<List<TextSpan>> pumpAndCollectSpans(
    WidgetTester tester,
    String body,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TwakeLinkPreview(
            event: _textEvent(body),
            localizedBody: body,
            ownMessage: false,
            fontSize: 14,
            linkStyle: linkStyle,
            richTextStyle: richTextStyle,
          ),
        ),
      ),
    );
    return _renderedSpans(tester);
  }

  List<TextSpan> _renderedSpans(WidgetTester tester) {
    final spans = <TextSpan>[];
    for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
      richText.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
    }
    return spans;
  }

  TextSpan spanWithText(List<TextSpan> spans, String text) =>
      spans.firstWhere((span) => span.text == text);

  /// The style a span is painted with: its own style merged over the styles of
  /// its parent spans.
  TextStyle paintedStyleOf(WidgetTester tester, String text) {
    TextStyle? painted;
    void visit(InlineSpan span, TextStyle parentStyle) {
      if (span is! TextSpan) return;
      final style = parentStyle.merge(span.style);
      if (span.text == text) painted = style;
      for (final child in span.children ?? const <InlineSpan>[]) {
        visit(child, style);
      }
    }

    for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
      visit(richText.text, const TextStyle());
    }
    return painted!;
  }
}

void main() {
  late _TwakeLinkPreviewHarness harness;

  setUpAll(() async {
    final room = Room(id: '!room:example.org', client: await getClient());
    harness = _TwakeLinkPreviewHarness(room);
  });

  group('TwakeLinkPreview filename handling', () {
    testWidgets('renders a filename as plain text, not as a link', (
      tester,
    ) async {
      final spans = await harness.pumpAndCollectSpans(
        tester,
        'see test.md for details',
      );

      final filename = harness.spanWithText(spans, 'test.md');
      final painted = harness.paintedStyleOf(tester, 'test.md');
      expect(filename, isNot(isA<LinkTextSpan>()));
      expect(painted.color, _TwakeLinkPreviewHarness.richTextStyle.color);
      expect(painted.decoration, isNot(TextDecoration.underline));
    });

    testWidgets('keeps styling a web address as a link', (tester) async {
      final spans = await harness.pumpAndCollectSpans(
        tester,
        'see test.md and example.com',
      );

      final link = harness.spanWithText(spans, 'example.com');
      expect(link, isA<LinkTextSpan>());
      expect(link.style, _TwakeLinkPreviewHarness.linkStyle);
    });

    testWidgets('keeps a www address as a link', (tester) async {
      final spans = await harness.pumpAndCollectSpans(
        tester,
        'see www.point.md for details',
      );

      final link = harness.spanWithText(spans, 'www.point.md');
      expect(link, isA<LinkTextSpan>());
      expect(link.style, _TwakeLinkPreviewHarness.linkStyle);
    });
  });
}
