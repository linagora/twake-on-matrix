import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/thread/thread_summary_card.dart';

/// THR-M-02: the card of a thread, inside the bubble of its root. Design
/// (Clément, 08/11): as the web ThreadCard (twake-space-chat
/// src/ds/ThreadCard/ThreadCard.tsx) — a paper card, radius 8, a 3 px left
/// border (primary when unread, neutral when read), « N messages › » in
/// primary w600, then one line « **Author**: text · relative age ».
void main() {
  /// Five minutes and a bit: far from a minute boundary while the test runs.
  DateTime fiveMinutesAgo() =>
      DateTime.now().subtract(const Duration(minutes: 5, seconds: 10));

  final primary = LinagoraSysColors.material().primary;

  /// Surfaces no default theme has: a colour of the card that equals one of
  /// them comes from the theme, not from a constant.
  const paper = Color(0xFF123456);
  const raised = Color(0xFF654321);
  final theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surfaceContainerLowest: paper,
      surfaceContainerHighest: raised,
    ),
  );

  Widget card({
    int replyCount = 3,
    int unreadCount = 0,
    VoidCallback? onTap,
    DateTime? lastReplyTime,
    bool onOwnBubble = false,
  }) => ThreadSummaryCard(
    replyCount: replyCount,
    lastReplyAuthor: 'Alice',
    lastReplyText: 'See you tomorrow',
    lastReplyTime: lastReplyTime ?? fiveMinutesAgo(),
    unreadCount: unreadCount,
    onOwnBubble: onOwnBubble,
    onTap: onTap ?? () {},
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    int replyCount = 3,
    int unreadCount = 0,
    VoidCallback? onTap,
    Locale locale = const Locale('en'),
    DateTime? lastReplyTime,
    bool onOwnBubble = false,
    double? maxWidth,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: theme,
      locale: locale,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            // Loose: the card picks its width inside it.
            constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
            child: card(
              replyCount: replyCount,
              unreadCount: unreadCount,
              onTap: onTap,
              lastReplyTime: lastReplyTime,
              onOwnBubble: onOwnBubble,
            ),
          ),
        ),
      ),
    ),
  );

  /// The frame of the card: the box that draws its border.
  BoxDecoration frame(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(ThreadSummaryCard),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .singleWhere((decoration) => decoration.border != null);

  /// The unread dot: a small primary circle.
  Finder unreadDot() => find.descendant(
    of: find.byType(ThreadSummaryCard),
    matching: find.byWidgetPredicate((widget) {
      final decoration = widget is DecoratedBox ? widget.decoration : null;
      return decoration is BoxDecoration &&
          decoration.shape == BoxShape.circle &&
          decoration.color == primary;
    }),
  );

  /// The painted text of a line of the card, found by its start.
  RichText line(WidgetTester tester, String start) => tester
      .widgetList<RichText>(
        find.descendant(
          of: find.byType(ThreadSummaryCard),
          matching: find.byType(RichText),
        ),
      )
      .singleWhere((text) => text.text.toPlainText().startsWith(start));

  /// The spans of [text] that carry their own text, with the style they are
  /// painted with (their parents' merged in).
  List<(String, TextStyle)> spansOf(InlineSpan text) {
    final spans = <(String, TextStyle)>[];
    void visit(InlineSpan span, TextStyle inherited) {
      final style = inherited.merge(span.style);
      if (span is TextSpan) {
        if (span.text != null && span.text!.isNotEmpty) {
          spans.add((span.text!, style));
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          visit(child, style);
        }
      }
    }

    visit(text, const TextStyle());
    return spans;
  }

  group('look of the card', () {
    testWidgets('a paper card with radius 8, distinct from the bubble', (
      tester,
    ) async {
      await pumpCard(tester);

      final decoration = frame(tester);
      expect(decoration.borderRadius, BorderRadius.circular(8));
      expect(decoration.color, isNotNull);
      expect(decoration.color!.a, 1.0, reason: 'an opaque paper surface');
    });

    testWidgets('an unread thread has a dot and a 3 px left border in the '
        'primary colour', (tester) async {
      await pumpCard(tester, unreadCount: 2);

      final border = frame(tester).border! as Border;
      expect(border.left.width, 3);
      expect(border.left.color, primary);
      expect(unreadDot(), findsOneWidget);
      expect(tester.getSize(unreadDot()), const Size(8, 8));
    });

    testWidgets('a read thread has no dot and a neutral left border', (
      tester,
    ) async {
      await pumpCard(tester);

      final border = frame(tester).border! as Border;
      expect(border.left.width, 3);
      expect(border.left.color, isNot(primary));
      expect(unreadDot(), findsNothing);
    });

    testWidgets('the number of messages is in primary, semi-bold', (
      tester,
    ) async {
      await pumpCard(tester);

      final style = line(tester, '3 messages').text.style!;
      expect(style.color, primary);
      expect(style.fontWeight, FontWeight.w600);
    });
  });

  /// THR-M-02, against the web ThreadCard (twake-space-chat
  /// src/ds/ThreadCard/ThreadCard.tsx): `display: block; width: 100%`, the
  /// count in `variant="caption"` w600 primary followed by the text « › »,
  /// `backgroundColor: palette.background.paper`. Here the paper is
  /// `ColorScheme.surfaceContainerLowest` (white in the light Twake theme,
  /// the darkest surface in the dark one), read from the theme.
  group('as the web card', () {
    testWidgets('stretches to the width it is given, not to its text', (
      tester,
    ) async {
      // Wider than the text of the card (12 px glyphs in tests: ~480 px).
      await pumpCard(tester, maxWidth: 700);

      expect(tester.getSize(find.byType(ThreadSummaryCard)).width, 700);
    });

    testWidgets('the number of messages is in the caption size, followed by '
        'the text « › », not an icon', (tester) async {
      await pumpCard(tester);

      final count = line(tester, '3 messages');
      expect(count.text.toPlainText(), '3 messages ›');
      expect(LinagoraTextStyle.material().bodySmall.fontSize, 12);
      expect(count.text.style!.fontSize, 12);
      expect(count.text.style!.fontWeight, FontWeight.w600);
      expect(count.text.style!.color, primary);
      expect(
        find.descendant(
          of: find.byType(ThreadSummaryCard),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
    });

    testWidgets('on the bubble of an own message, the card is the paper of '
        'the theme', (tester) async {
      await pumpCard(tester, onOwnBubble: true);

      expect(frame(tester).color, paper);
    });

    testWidgets('on a received bubble, the card is the raised surface of the '
        'theme', (tester) async {
      await pumpCard(tester);

      expect(frame(tester).color, raised);
    });
  });

  group('the last reply', () {
    testWidgets('is one line, cut with an ellipsis', (tester) async {
      await pumpCard(tester);

      final text = line(tester, 'Alice: See you tomorrow · ');
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('shows its author in semi-bold, the text in regular', (
      tester,
    ) async {
      await pumpCard(tester);

      final spans = spansOf(line(tester, 'Alice: See you tomorrow · ').text);
      final author = spans.where((span) => span.$1 == 'Alice');
      expect(author, hasLength(1), reason: 'the author is a span of its own');
      expect(author.single.$2.fontWeight, FontWeight.w600);
      final rest = spans.where((span) => span.$1.contains('See you tomorrow'));
      expect(rest.single.$2.fontWeight, isNot(FontWeight.w600));
    });

    testWidgets('shows how long ago it was sent, not the time of day', (
      tester,
    ) async {
      await pumpCard(tester);

      final plain = line(
        tester,
        'Alice: See you tomorrow · ',
      ).text.toPlainText();
      expect(plain, 'Alice: See you tomorrow · 5 minutes ago');
      expect(plain, isNot(matches(RegExp(r'\d{1,2}:\d{2}'))));
    });

    testWidgets('says the age in the language of the app', (tester) async {
      await pumpCard(tester, locale: const Locale('fr'));

      expect(
        line(tester, 'Alice: See you tomorrow · ').text.toPlainText(),
        'Alice: See you tomorrow · il y a 5 minutes',
      );
    });

    testWidgets('accessibility reads the age too', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(tester);

      expect(
        find.bySemanticsLabel(
          RegExp('3 messages.*Alice: See you tomorrow · 5 minutes ago'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  testWidgets('shows the number of messages of the thread', (tester) async {
    await pumpCard(tester, replyCount: 3);

    expect(
      find.textContaining('3 messages', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('shows the author and the text of the last reply', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.textContaining('Alice', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('See you tomorrow', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('announces the unread messages to accessibility', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(tester, unreadCount: 2);

    expect(find.bySemanticsLabel(RegExp('2 unread messages')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('announces no unread messages when the thread is read', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(tester);

    expect(find.bySemanticsLabel(RegExp('unread messages')), findsNothing);
    semantics.dispose();
  });

  testWidgets('tapping the card opens the thread', (tester) async {
    var opened = 0;
    await pumpCard(tester, onTap: () => opened++);

    await tester.tap(find.textContaining('3 messages', findRichText: true));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('the card is reachable as a button by accessibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(tester);

    expect(
      tester.getSemantics(find.byType(ThreadSummaryCard)),
      containsSemantics(isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });
}
