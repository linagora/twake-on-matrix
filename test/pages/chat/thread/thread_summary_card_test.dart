import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  /// What the card looks like on screen, pixel by pixel.
  const cardPicture = Key('card-picture');

  Widget card({
    int replyCount = 3,
    int unreadCount = 0,
    VoidCallback? onTap,
    DateTime? lastReplyTime,
    bool onOwnBubble = false,
    String lastReplyText = 'See you tomorrow',
  }) => ThreadSummaryCard(
    replyCount: replyCount,
    lastReplyAuthor: 'Alice',
    lastReplyText: lastReplyText,
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
    TextDirection direction = TextDirection.ltr,
    String lastReplyText = 'See you tomorrow',
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
        body: Directionality(
          textDirection: direction,
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              // Loose: the card picks its width inside it.
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? double.infinity,
              ),
              child: RepaintBoundary(
                key: cardPicture,
                child: card(
                  replyCount: replyCount,
                  unreadCount: unreadCount,
                  onTap: onTap,
                  lastReplyTime: lastReplyTime,
                  onOwnBubble: onOwnBubble,
                  lastReplyText: lastReplyText,
                ),
              ),
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

  /// Every painted paragraph of the card, as laid out on screen.
  List<RenderParagraph> paragraphs(WidgetTester tester) => tester
      .widgetList<RichText>(
        find.descendant(
          of: find.byType(ThreadSummaryCard),
          matching: find.byType(RichText),
        ),
      )
      .map((text) => tester.renderObject<RenderParagraph>(find.byWidget(text)))
      .toList();

  /// The paragraph of the card that shows [text], whatever else it shows.
  RenderParagraph paragraphShowing(WidgetTester tester, String text) =>
      paragraphs(tester).firstWhere(
        (p) => p.text.toPlainText().contains(text),
        orElse: () => fail('no paragraph of the card shows « $text »'),
      );

  /// [paragraph] does not show all of [full]: cut by the ellipsis of the
  /// layout, or shortened by hand with « … ».
  bool isCut(RenderParagraph paragraph, String full) {
    final plain = paragraph.text.toPlainText();
    return paragraph.didExceedMaxLines ||
        (plain.contains('…') && !plain.contains(full));
  }

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

  /// THR-M-02, RTL: in a right-to-left language the card reads from the
  /// right, like the web card (`border-left` follows `dir`): its coloured bar
  /// on the start side, the unread dot before the count, a gap between them.
  group('right to left', () {
    /// The colour painted at [dx] of the middle row of the card.
    Future<Color> pixelAt(WidgetTester tester, double Function(Size) dx) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(cardPicture),
      );
      final size = boundary.size;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ImageByteFormat.rawRgba);
        image.dispose();
        return data!;
      });
      final x = dx(size).floor();
      final y = (size.height / 2).floor();
      final offset = (y * size.width.toInt() + x) * 4;
      return Color.fromARGB(
        bytes!.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      );
    }

    bool isPrimary(Color color) =>
        (color.r - primary.r).abs() < 0.02 &&
        (color.g - primary.g).abs() < 0.02 &&
        (color.b - primary.b).abs() < 0.02;

    /// Inside a 3 px bar on the left, and on the right.
    double nearLeft(Size size) => 1;
    double nearRight(Size size) => size.width - 2;

    testWidgets('the bar of an unread thread is on the right', (tester) async {
      await pumpCard(tester, unreadCount: 2, direction: TextDirection.rtl);

      expect(isPrimary(await pixelAt(tester, nearRight)), isTrue);
      expect(isPrimary(await pixelAt(tester, nearLeft)), isFalse);
    });

    testWidgets('left to right, the bar is on the left', (tester) async {
      await pumpCard(tester, unreadCount: 2);

      expect(isPrimary(await pixelAt(tester, nearLeft)), isTrue);
      expect(isPrimary(await pixelAt(tester, nearRight)), isFalse);
    });

    testWidgets('the unread dot is on the right of the count, 6 px apart', (
      tester,
    ) async {
      await pumpCard(tester, unreadCount: 2, direction: TextDirection.rtl);

      final dot = tester.getRect(unreadDot());
      final count = tester.getRect(
        find.textContaining('3 messages', findRichText: true),
      );
      expect(dot.left, greaterThanOrEqualTo(count.right));
      expect(dot.left - count.right, moreOrLessEquals(6));
    });

    testWidgets('left to right, the unread dot is on the left of the count, '
        '6 px apart', (tester) async {
      await pumpCard(tester, unreadCount: 2);

      final dot = tester.getRect(unreadDot());
      final count = tester.getRect(
        find.textContaining('3 messages', findRichText: true),
      );
      expect(count.left - dot.right, moreOrLessEquals(6));
    });
  });

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
    testWidgets('shows its author in semi-bold, the text in regular', (
      tester,
    ) async {
      await pumpCard(tester);

      final spans = spansOf(line(tester, 'Alice').text);
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

      expect(
        find.textContaining('Alice: See you tomorrow', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('5 minutes ago', findRichText: true),
        findsOneWidget,
      );
      for (final paragraph in paragraphs(tester)) {
        expect(
          paragraph.text.toPlainText(),
          isNot(matches(RegExp(r'\d{1,2}:\d{2}'))),
        );
      }
    });

    testWidgets('says the age in the language of the app', (tester) async {
      await pumpCard(tester, locale: const Locale('fr'));

      expect(
        find.textContaining('il y a 5 minutes', findRichText: true),
        findsOneWidget,
      );
    });

    /// THR-M-02, decision of the maintainer (09/11): the relative age of the
    /// last reply stays whole; only the text of the reply is cut with an
    /// ellipsis once the line reaches the width the card is given.
    group('longer than the card', () {
      const long =
          'Let us meet on Thursday at the usual place near the station';

      // 12 px glyphs in tests: the line is ~900 px, the card 300.
      Future<void> pumpLong(WidgetTester tester) =>
          pumpCard(tester, maxWidth: 300, lastReplyText: long);

      testWidgets('keeps its age whole, inside the card', (tester) async {
        await pumpLong(tester);

        expect(tester.takeException(), isNull);
        final age = paragraphShowing(tester, '5 minutes ago');
        expect(
          age.didExceedMaxLines,
          isFalse,
          reason: 'the age is cut with the reply',
        );
        expect(
          age.size.width,
          moreOrLessEquals(
            age.getMaxIntrinsicWidth(double.infinity),
            epsilon: 0.5,
          ),
          reason: 'the age is on one line, not wrapped',
        );
        final cardRect = tester.getRect(find.byType(ThreadSummaryCard));
        final ageRect = age.localToGlobal(Offset.zero) & age.size;
        expect(ageRect.left, greaterThanOrEqualTo(cardRect.left));
        expect(ageRect.right, lessThanOrEqualTo(cardRect.right));
      });

      testWidgets('keeps the dot before the age', (tester) async {
        await pumpLong(tester);

        final withDot = paragraphs(
          tester,
        ).where((p) => p.text.toPlainText().contains('·'));
        expect(withDot, isNotEmpty);
        for (final paragraph in withDot) {
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: 'the dot is cut with the reply',
          );
        }
      });

      testWidgets('cuts the text of the reply with an ellipsis, on one line', (
        tester,
      ) async {
        await pumpLong(tester);

        final reply = paragraphShowing(tester, 'Alice');
        expect(isCut(reply, long), isTrue);
        final count = paragraphShowing(tester, '3 messages');
        expect(reply.size.height, lessThan(2 * count.size.height));
      });

      testWidgets('shows the age after the text, on the same line', (
        tester,
      ) async {
        await pumpLong(tester);

        final reply = paragraphShowing(tester, 'Alice');
        final age = paragraphShowing(tester, '5 minutes ago');
        final replyRect = reply.localToGlobal(Offset.zero) & reply.size;
        final ageRect = age.localToGlobal(Offset.zero) & age.size;
        expect(
          ageRect.center.dy,
          moreOrLessEquals(replyRect.center.dy, epsilon: 2),
        );
        if (!identical(reply, age)) {
          expect(ageRect.left, greaterThanOrEqualTo(replyRect.right - 0.5));
        }
      });
    });

    testWidgets('that fits the card is not cut at all', (tester) async {
      await pumpCard(tester, maxWidth: 700);

      expect(tester.takeException(), isNull);
      for (final paragraph in paragraphs(tester)) {
        expect(
          isCut(paragraph, 'Alice: See you tomorrow'),
          isFalse,
          reason: '« ${paragraph.text.toPlainText()} » is cut',
        );
      }
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
