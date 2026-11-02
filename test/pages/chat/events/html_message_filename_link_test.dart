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

void main() {
  late Room room;

  setUpAll(() async {
    room = Room(id: '!room:example.org', client: await getClient());
  });

  void collect(
    InlineSpan span,
    TextStyle parentStyle,
    List<_RenderedSpan> out,
  ) {
    if (span is! TextSpan) return;
    final style = parentStyle.merge(span.style);
    if (span.text != null) out.add((span: span, style: style));
    for (final child in span.children ?? const <InlineSpan>[]) {
      collect(child, style, out);
    }
  }

  Future<_RenderedSpan> pumpAndFind(
    WidgetTester tester,
    String html,
    String text,
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
      collect(richText.text, const TextStyle(), spans);
    }
    return spans.firstWhere((rendered) => rendered.span.text == text);
  }

  group('HtmlMessage filename links', () {
    testWidgets('renders a filename in a formatted message as plain text', (
      tester,
    ) async {
      final filename = await pumpAndFind(tester, '<p>test.md</p>', 'test.md');

      expect(filename.span.recognizer, isNull);
      expect(filename.style.color, _textStyle.color);
      expect(filename.style.decoration, TextDecoration.none);
    });

    testWidgets('keeps the nested formatting of a filename anchor', (
      tester,
    ) async {
      final bold = await pumpAndFind(
        tester,
        '<p><a href="report.md"><b>my</b> report</a></p>',
        'my',
      );

      expect(bold.span.recognizer, isNull);
      expect(bold.style.fontWeight, FontWeight.bold);
      expect(bold.style.color, _textStyle.color);
      expect(bold.style.decoration, TextDecoration.none);
    });

    testWidgets('keeps a web address as a link', (tester) async {
      final link = await pumpAndFind(
        tester,
        '<p>example.com</p>',
        'example.com',
      );

      expect(link.span.recognizer, isNotNull);
      expect(link.style.color, _linkStyle.color);
      expect(link.style.decoration, TextDecoration.underline);
    });
  });
}
