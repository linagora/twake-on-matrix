import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/pages/chat/events/html_message.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../../../fake_client.dart';

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

const _textStyle = TextStyle(color: Colors.black);
const _linkStyle = TextStyle(
  color: Colors.blue,
  decoration: TextDecoration.underline,
);

/// A rendered text span with the style it is painted with (merged with the
/// styles of its parent spans).
typedef _RenderedSpan = ({TextSpan span, TextStyle style});

class _HtmlMessageHarness {
  final Room room;

  _HtmlMessageHarness(this.room);

  void _collect(
    InlineSpan span,
    TextStyle parentStyle,
    List<_RenderedSpan> out,
  ) {
    if (span is! TextSpan) return;
    final style = parentStyle.merge(span.style);
    if (span.text != null) out.add((span: span, style: style));
    for (final child in span.children ?? const <InlineSpan>[]) {
      _collect(child, style, out);
    }
  }

  Future<List<_RenderedSpan>> pumpAndCollect(
    WidgetTester tester,
    String html,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<MatrixState>.value(
          value: _FakeMatrixState(room.client),
          child: Scaffold(
            body: HtmlMessage(
              html: html,
              room: room,
              defaultTextStyle: _textStyle,
              linkStyle: _linkStyle,
            ),
          ),
        ),
      ),
    );
    final spans = <_RenderedSpan>[];
    for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
      _collect(richText.text, const TextStyle(), spans);
    }
    return spans;
  }

  Future<_RenderedSpan> pumpAndFind(
    WidgetTester tester,
    String html,
    String text,
  ) async {
    final spans = await pumpAndCollect(tester, html);
    return spans.firstWhere((rendered) => rendered.span.text == text);
  }

  void expectPlainText(_RenderedSpan rendered) {
    expect(rendered.span.recognizer, isNull);
    expect(rendered.style.color, _textStyle.color);
    expect(rendered.style.decoration, TextDecoration.none);
  }
}

void main() {
  late _HtmlMessageHarness harness;

  setUpAll(() async {
    final room = Room(id: '!room:example.org', client: await getClient());
    harness = _HtmlMessageHarness(room);
  });

  group('HtmlMessage filename links', () {
    testWidgets('renders a filename in a formatted message as plain text', (
      tester,
    ) async {
      final filename = await harness.pumpAndFind(
        tester,
        '<p>test.md</p>',
        'test.md',
      );

      harness.expectPlainText(filename);
    });

    testWidgets('keeps the nested formatting of a filename anchor', (
      tester,
    ) async {
      final bold = await harness.pumpAndFind(
        tester,
        '<p><a href="report.md"><b>my</b> report</a></p>',
        'my',
      );

      harness.expectPlainText(bold);
      expect(bold.style.fontWeight, FontWeight.bold);
    });

    testWidgets(
      'keeps a mailto link whose domain looks like a file extension',
      (tester) async {
        final link = await harness.pumpAndFind(
          tester,
          '<p><a href="mailto:bob@acme.rs">write to bob</a></p>',
          'write to bob',
        );

        expect(link.span.recognizer, isNotNull);
        expect(link.style.color, _linkStyle.color);
        expect(link.style.decoration, TextDecoration.underline);
      },
    );

    testWidgets('keeps a web address as a link', (tester) async {
      final link = await harness.pumpAndFind(
        tester,
        '<p>example.com</p>',
        'example.com',
      );

      expect(link.span.recognizer, isNotNull);
      expect(link.style.color, _linkStyle.color);
      expect(link.style.decoration, TextDecoration.underline);
    });
  });

  group('HtmlMessage reply fallback', () {
    testWidgets('hides a nested reply fallback entirely (#3237)', (
      tester,
    ) async {
      final spans = await harness.pumpAndCollect(
        tester,
        '<mx-reply><blockquote>In reply to @bob<br>'
        '<mx-reply><blockquote>In reply to @alice<br>First message'
        '</blockquote></mx-reply>'
        'Second message</blockquote></mx-reply>'
        'My answer',
      );
      final rendered = spans.map((rendered) => rendered.span.text).join();

      expect(rendered, 'My answer');
    });
  });
}
