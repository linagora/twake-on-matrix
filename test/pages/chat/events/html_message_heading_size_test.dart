// Need (Clément, 2026-11-26): on mobile a formatted message with Markdown
// headings (release notes: `# Title`, `## Section`) is far too big; it must
// look like the web app. Twake Space Chat draws every heading of a message
// at the size of the message text, bold, with no margin
// (`src/ds/MessageBubble/MessageBubble.tsx`:
// `'& h1, & h2, & h3, & h4, & h5, & h6': { fontSize: '1em', m: 0 }`,
// `'& p': { m: 0 }`; the bold is the browser default for h1..h6).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
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

/// The text style of a message in its bubble (`Event.getMessageTextStyle`).
final _bubbleTextStyle = LinagoraTextThemeExtension.material().bodyMedium4;

Future<void> _pump(
  WidgetTester tester,
  Room room,
  String html, {
  double width = 600,
}) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    home: Provider<MatrixState>.value(
      value: _FakeMatrixState(room.client),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: HtmlMessage(
              html: html,
              room: room,
              defaultTextStyle: _bubbleTextStyle,
              linkStyle: const TextStyle(color: Colors.blue),
            ),
          ),
        ),
      ),
    ),
  ),
);

TextStyle? _styleIn(InlineSpan span, TextStyle inherited, String needle) {
  final style = inherited.merge(span.style);
  if (span is! TextSpan) return null;
  if (span.text?.contains(needle) ?? false) return style;
  for (final child in span.children ?? const <InlineSpan>[]) {
    final found = _styleIn(child, style, needle);
    if (found != null) return found;
  }
  return null;
}

/// The style the reader sees on [needle]: every style above it, merged.
TextStyle _styleOf(WidgetTester tester, String needle) {
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    final found = _styleIn(richText.text, const TextStyle(), needle);
    if (found != null) return found;
  }
  fail('« $needle » is not on screen');
}

/// The block of text that shows [needle].
Finder _block(String needle) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText().contains(needle),
);

void main() {
  late Room room;

  setUpAll(() async {
    final client = await getClient();
    room = Room(id: '!group:example.org', client: client);
  });

  group('HtmlMessage headings look like the web app', () {
    for (var level = 1; level <= 6; level++) {
      testWidgets('an h$level is written at the size of the message text', (
        tester,
      ) async {
        await _pump(tester, room, '<h$level>Heading</h$level><p>Body</p>');

        expect(
          _styleOf(tester, 'Heading').fontSize,
          _styleOf(tester, 'Body').fontSize,
        );
      });

      testWidgets('an h$level is bold', (tester) async {
        await _pump(tester, room, '<h$level>Heading</h$level><p>Body</p>');

        expect(_styleOf(tester, 'Heading').fontWeight, FontWeight.bold);
      });
    }

    testWidgets('a title that fits on one line as plain text stays on one '
        'line as an h1, as high as a line of the message', (tester) async {
      const title = 'Twake Chat 2.19.0';
      // Wide enough for the title at the size of the message text (the test
      // font draws every glyph one font size wide), with two glyphs to spare.
      final width = (title.length + 2) * _bubbleTextStyle.fontSize!;
      await _pump(tester, room, '<h1>$title</h1><p>Body</p>', width: width);

      expect(
        tester.getSize(_block(title)).height,
        tester.getSize(_block('Body')).height,
      );
    });

    testWidgets('a heading has no margin: the paragraph under it starts '
        'where the heading ends', (tester) async {
      await _pump(tester, room, '<h2>Heading</h2><p>Body</p>');

      expect(
        tester.getTopLeft(_block('Body')).dy,
        tester.getBottomLeft(_block('Heading')).dy,
      );
    });

    testWidgets('release notes: title, section, bold line and list item are '
        'all at the size of the message text', (tester) async {
      await _pump(
        tester,
        room,
        '<h1>Release</h1><h2>Section</h2><p><strong>Calls</strong></p>'
        '<ul><li>Ringing</li></ul><p>Body</p>',
      );

      final bodySize = _styleOf(tester, 'Body').fontSize;
      expect(
        {
          for (final text in ['Release', 'Section', 'Calls', 'Ringing'])
            text: _styleOf(tester, text).fontSize,
        },
        {
          for (final text in ['Release', 'Section', 'Calls', 'Ringing'])
            text: bodySize,
        },
      );
    });
  });
}
