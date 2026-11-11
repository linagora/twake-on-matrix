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
  group('right to left', _rightToLeftTests);
  group('look of the card', _lookTests);
  group('as the web card', _webCardTests);
  group('the last reply', _lastReplyTests);
  _countAndTapTests();
  _accessibilityTests();
  group('the unread count says one or several messages', _unreadPluralTests);
}

/// CodeRabbit 4515287889: « 1 unread messages » was a raw `{n}`; the
/// string is an ICU plural, as `threadMessagesCount` next to it. The French
/// strings are Weblate's (661311f66): no French text is asserted here.
void _unreadPluralTests() {
  final en = lookupL10n(const Locale('en'));

  test('in English', () {
    expect(en.threadUnreadMessagesCount(1), '1 unread message');
    expect(en.threadUnreadMessagesCount(2), '2 unread messages');
  });
}

/// Five minutes and a bit: far from a minute boundary while the test runs.
DateTime _fiveMinutesAgo() =>
    DateTime.now().subtract(const Duration(minutes: 5, seconds: 10));

final _primary = LinagoraSysColors.material().primary;

/// Surfaces no default theme has: a colour of the card that equals one of
/// them comes from the theme, not from a constant.
const _paper = Color(0xFF123456);
const _raised = Color(0xFF654321);
final _theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _primary,
    primary: _primary,
    surfaceContainerLowest: _paper,
    surfaceContainerHighest: _raised,
  ),
);

/// What the card looks like on screen, pixel by pixel.
const _cardPicture = Key('card-picture');

/// What a test changes in the card and around it; set by cascade, e.g.
/// `_CardSpec()..unreadCount = 2`.
class _CardSpec {
  int replyCount = 3;
  int unreadCount = 0;
  VoidCallback onTap = () {};
  bool onOwnBubble = false;
  String lastReplyText = 'See you tomorrow';
  Locale locale = const Locale('en');
  double maxWidth = double.infinity;
  TextDirection direction = TextDirection.ltr;
}

Future<void> _pumpCard(WidgetTester tester, [_CardSpec? spec]) {
  final card = spec ?? _CardSpec();
  return tester.pumpWidget(
    MaterialApp(
      theme: _theme,
      locale: card.locale,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.supportedLocales,
      home: Scaffold(
        body: Directionality(
          textDirection: card.direction,
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              // Loose: the card picks its width inside it.
              constraints: BoxConstraints(maxWidth: card.maxWidth),
              child: RepaintBoundary(
                key: _cardPicture,
                child: ThreadSummaryCard(
                  replyCount: card.replyCount,
                  lastReplyAuthor: 'Alice',
                  lastReplyText: card.lastReplyText,
                  lastReplyTime: _fiveMinutesAgo(),
                  unreadCount: card.unreadCount,
                  onOwnBubble: card.onOwnBubble,
                  onTap: card.onTap,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Runs [body] with the semantics tree on.
Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final semantics = tester.ensureSemantics();
  await body();
  semantics.dispose();
}

Finder _inCard(Finder matching) =>
    find.descendant(of: find.byType(ThreadSummaryCard), matching: matching);

Finder _text(String text) => find.textContaining(text, findRichText: true);

/// The frame of the card: the box that draws its border.
BoxDecoration _frame(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(_inCard(find.byType(DecoratedBox)))
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .singleWhere((decoration) => decoration.border != null);

/// The unread dot: a small primary circle.
Finder _unreadDot() => _inCard(
  find.byWidgetPredicate((widget) {
    final decoration = widget is DecoratedBox ? widget.decoration : null;
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color == _primary;
  }),
);

Iterable<RichText> _richTexts(WidgetTester tester) =>
    tester.widgetList<RichText>(_inCard(find.byType(RichText)));

/// The painted text of a line of the card, found by its start.
RichText _line(WidgetTester tester, String start) => _richTexts(
  tester,
).singleWhere((text) => text.text.toPlainText().startsWith(start));

/// Every painted paragraph of the card, as laid out on screen.
List<RenderParagraph> _paragraphs(WidgetTester tester) => _richTexts(tester)
    .map((text) => tester.renderObject<RenderParagraph>(find.byWidget(text)))
    .toList();

/// The paragraph of the card that shows [text], whatever else it shows.
RenderParagraph _paragraphShowing(WidgetTester tester, String text) =>
    _paragraphs(tester).firstWhere(
      (p) => p.text.toPlainText().contains(text),
      orElse: () => fail('no paragraph of the card shows « $text »'),
    );

Rect _rectOf(RenderBox box) => box.localToGlobal(Offset.zero) & box.size;

/// [paragraph] does not show all of [full]: cut by the ellipsis of the
/// layout, or shortened by hand with « … ».
bool _isCut(RenderParagraph paragraph, String full) {
  final plain = paragraph.text.toPlainText();
  return paragraph.didExceedMaxLines ||
      (plain.contains('…') && !plain.contains(full));
}

/// The spans of [text] that carry their own text, with the style they are
/// painted with (their parents' merged in).
List<(String, TextStyle)> _spansOf(InlineSpan text) {
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

/// The colour painted at [dx] of the middle row of the card.
Future<Color> _pixelAt(WidgetTester tester, double Function(Size) dx) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_cardPicture),
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

bool _isPrimary(Color color) =>
    (color.r - _primary.r).abs() < 0.02 &&
    (color.g - _primary.g).abs() < 0.02 &&
    (color.b - _primary.b).abs() < 0.02;

/// Inside a 3 px bar on the left, and on the right.
double _nearLeft(Size size) => 1;
double _nearRight(Size size) => size.width - 2;

/// Whether the bar is painted on the left and on the right of the card.
Future<(bool, bool)> _barOnLeftAndRight(WidgetTester tester) async => (
  _isPrimary(await _pixelAt(tester, _nearLeft)),
  _isPrimary(await _pixelAt(tester, _nearRight)),
);

/// The unread dot and the count of an unread card in [direction].
Future<(Rect, Rect)> _dotAndCount(
  WidgetTester tester,
  TextDirection direction,
) async {
  await _pumpCard(
    tester,
    _CardSpec()
      ..unreadCount = 2
      ..direction = direction,
  );
  return (tester.getRect(_unreadDot()), tester.getRect(_text('3 messages')));
}

/// THR-M-02, RTL: in a right-to-left language the card reads from the
/// right, like the web card (`border-left` follows `dir`): its coloured bar
/// on the start side, the unread dot before the count, a gap between them.
void _rightToLeftTests() {
  testWidgets('the bar of an unread thread is on the right', (tester) async {
    await _pumpCard(
      tester,
      _CardSpec()
        ..unreadCount = 2
        ..direction = TextDirection.rtl,
    );

    expect(await _barOnLeftAndRight(tester), (false, true));
  });

  testWidgets('left to right, the bar is on the left', (tester) async {
    await _pumpCard(tester, _CardSpec()..unreadCount = 2);

    expect(await _barOnLeftAndRight(tester), (true, false));
  });

  testWidgets('the unread dot is on the right of the count, 6 px apart', (
    tester,
  ) async {
    final (dot, count) = await _dotAndCount(tester, TextDirection.rtl);

    expect(dot.left, greaterThanOrEqualTo(count.right));
    expect(dot.left - count.right, moreOrLessEquals(6));
  });

  testWidgets('left to right, the unread dot is on the left of the count, '
      '6 px apart', (tester) async {
    final (dot, count) = await _dotAndCount(tester, TextDirection.ltr);

    expect(count.left - dot.right, moreOrLessEquals(6));
  });
}

void _lookTests() {
  testWidgets('a paper card with radius 8, distinct from the bubble', (
    tester,
  ) async {
    await _pumpCard(tester);

    final decoration = _frame(tester);
    expect(decoration.borderRadius, BorderRadius.circular(8));
    expect(decoration.color, isNotNull);
    expect(decoration.color!.a, 1.0, reason: 'an opaque paper surface');
  });

  testWidgets('an unread thread has a dot and a 3 px left border in the '
      'primary colour', (tester) async {
    await _pumpCard(tester, _CardSpec()..unreadCount = 2);

    final border = _frame(tester).border! as Border;
    expect(border.left.width, 3);
    expect(border.left.color, _primary);
    expect(_unreadDot(), findsOneWidget);
    expect(tester.getSize(_unreadDot()), const Size(8, 8));
  });

  testWidgets('a read thread has no dot and a neutral left border', (
    tester,
  ) async {
    await _pumpCard(tester);

    final border = _frame(tester).border! as Border;
    expect(border.left.width, 3);
    expect(border.left.color, isNot(_primary));
    expect(_unreadDot(), findsNothing);
  });

  testWidgets('the number of messages is in primary, semi-bold', (
    tester,
  ) async {
    await _pumpCard(tester);

    final style = _line(tester, '3 messages').text.style!;
    expect(style.color, _primary);
    expect(style.fontWeight, FontWeight.w600);
  });
}

/// THR-M-02, against the web ThreadCard (twake-space-chat
/// src/ds/ThreadCard/ThreadCard.tsx): `display: block; width: 100%`, the
/// count in `variant="caption"` w600 primary followed by the text « › »,
/// `backgroundColor: palette.background.paper`. Here the paper is
/// `ColorScheme.surfaceContainerLowest` (white in the light Twake theme,
/// the darkest surface in the dark one), read from the theme.
void _webCardTests() {
  testWidgets('stretches to the width it is given, not to its text', (
    tester,
  ) async {
    // Wider than the text of the card (12 px glyphs in tests: ~480 px).
    await _pumpCard(tester, _CardSpec()..maxWidth = 700);

    expect(tester.getSize(find.byType(ThreadSummaryCard)).width, 700);
  });

  testWidgets('the number of messages is in the caption size, followed by '
      'the text « › », not an icon', (tester) async {
    await _pumpCard(tester);

    final count = _line(tester, '3 messages');
    expect(count.text.toPlainText(), '3 messages ›');
    expect(LinagoraTextStyle.material().bodySmall.fontSize, 12);
    expect(count.text.style!.fontSize, 12);
    expect(count.text.style!.fontWeight, FontWeight.w600);
    expect(count.text.style!.color, _primary);
    expect(_inCard(find.byType(Icon)), findsNothing);
  });

  testWidgets('on the bubble of an own message, the card is the paper of '
      'the theme', (tester) async {
    await _pumpCard(tester, _CardSpec()..onOwnBubble = true);

    expect(_frame(tester).color, _paper);
  });

  testWidgets('on a received bubble, the card is the raised surface of the '
      'theme', (tester) async {
    await _pumpCard(tester);

    expect(_frame(tester).color, _raised);
  });
}

void _lastReplyTests() {
  testWidgets('shows its author in semi-bold, the text in regular', (
    tester,
  ) async {
    await _pumpCard(tester);

    final spans = _spansOf(_line(tester, 'Alice').text);
    final author = spans.where((span) => span.$1 == 'Alice');
    expect(author, hasLength(1), reason: 'the author is a span of its own');
    expect(author.single.$2.fontWeight, FontWeight.w600);
    final rest = spans.where((span) => span.$1.contains('See you tomorrow'));
    expect(rest.single.$2.fontWeight, isNot(FontWeight.w600));
  });

  testWidgets('shows how long ago it was sent, not the time of day', (
    tester,
  ) async {
    await _pumpCard(tester);

    expect(_text('Alice: See you tomorrow'), findsOneWidget);
    expect(_text('5 minutes ago'), findsOneWidget);
    for (final paragraph in _paragraphs(tester)) {
      expect(
        paragraph.text.toPlainText(),
        isNot(matches(RegExp(r'\d{1,2}:\d{2}'))),
      );
    }
  });

  /// The text of the age is Weblate's (661311f66): the card takes it from
  /// the strings of the app locale, whatever they say.
  testWidgets('says the age in the language of the app', (tester) async {
    const french = Locale('fr');
    await _pumpCard(tester, _CardSpec()..locale = french);

    expect(_text(lookupL10n(french).ageMinutesAgo(5)), findsOneWidget);
  });

  group('longer than the card', _longReplyTests);

  testWidgets('that fits the card is not cut at all', (tester) async {
    await _pumpCard(tester, _CardSpec()..maxWidth = 700);

    expect(tester.takeException(), isNull);
    for (final paragraph in _paragraphs(tester)) {
      expect(
        _isCut(paragraph, 'Alice: See you tomorrow'),
        isFalse,
        reason: '« ${paragraph.text.toPlainText()} » is cut',
      );
    }
  });

  testWidgets('accessibility reads the age too', (tester) async {
    await _withSemantics(tester, () async {
      await _pumpCard(tester);

      expect(
        find.bySemanticsLabel(
          RegExp('3 messages.*Alice: See you tomorrow · 5 minutes ago'),
        ),
        findsOneWidget,
      );
    });
  });
}

const _long = 'Let us meet on Thursday at the usual place near the station';

// 12 px glyphs in tests: the line is ~900 px, the card 300.
Future<void> _pumpLong(WidgetTester tester) => _pumpCard(
  tester,
  _CardSpec()
    ..maxWidth = 300
    ..lastReplyText = _long,
);

/// THR-M-02, decision of the maintainer (09/11): the relative age of the
/// last reply stays whole; only the text of the reply is cut with an
/// ellipsis once the line reaches the width the card is given.
void _longReplyTests() {
  testWidgets('keeps its age whole, inside the card', (tester) async {
    await _pumpLong(tester);

    expect(tester.takeException(), isNull);
    final age = _paragraphShowing(tester, '5 minutes ago');
    expect(
      age.didExceedMaxLines,
      isFalse,
      reason: 'the age is cut with the reply',
    );
    expect(
      age.size.width,
      moreOrLessEquals(age.getMaxIntrinsicWidth(double.infinity), epsilon: 0.5),
      reason: 'the age is on one line, not wrapped',
    );
    final cardRect = tester.getRect(find.byType(ThreadSummaryCard));
    final ageRect = _rectOf(age);
    expect(ageRect.left, greaterThanOrEqualTo(cardRect.left));
    expect(ageRect.right, lessThanOrEqualTo(cardRect.right));
  });

  testWidgets('keeps the dot before the age', (tester) async {
    await _pumpLong(tester);

    final withDot = _paragraphs(
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
    await _pumpLong(tester);

    final reply = _paragraphShowing(tester, 'Alice');
    expect(_isCut(reply, _long), isTrue);
    final count = _paragraphShowing(tester, '3 messages');
    expect(reply.size.height, lessThan(2 * count.size.height));
  });

  testWidgets('shows the age after the text, on the same line', (tester) async {
    await _pumpLong(tester);

    final reply = _paragraphShowing(tester, 'Alice');
    final age = _paragraphShowing(tester, '5 minutes ago');
    final replyRect = _rectOf(reply);
    final ageRect = _rectOf(age);
    expect(
      ageRect.center.dy,
      moreOrLessEquals(replyRect.center.dy, epsilon: 2),
    );
    if (!identical(reply, age)) {
      expect(ageRect.left, greaterThanOrEqualTo(replyRect.right - 0.5));
    }
  });
}

void _countAndTapTests() {
  testWidgets('shows the number of messages of the thread', (tester) async {
    await _pumpCard(tester, _CardSpec()..replyCount = 3);

    expect(_text('3 messages'), findsOneWidget);
  });

  testWidgets('shows the author and the text of the last reply', (
    tester,
  ) async {
    await _pumpCard(tester);

    expect(_text('Alice'), findsOneWidget);
    expect(_text('See you tomorrow'), findsOneWidget);
  });

  testWidgets('tapping the card opens the thread', (tester) async {
    var opened = 0;
    await _pumpCard(tester, _CardSpec()..onTap = () => opened++);

    await tester.tap(_text('3 messages'));
    await tester.pump();

    expect(opened, 1);
  });
}

void _accessibilityTests() {
  testWidgets('announces the unread messages to accessibility', (tester) async {
    await _withSemantics(tester, () async {
      await _pumpCard(tester, _CardSpec()..unreadCount = 2);

      expect(
        find.bySemanticsLabel(RegExp('2 unread messages')),
        findsOneWidget,
      );
    });
  });

  testWidgets('announces no unread messages when the thread is read', (
    tester,
  ) async {
    await _withSemantics(tester, () async {
      await _pumpCard(tester);

      expect(find.bySemanticsLabel(RegExp('unread messages')), findsNothing);
    });
  });

  testWidgets('the card is reachable as a button by accessibility', (
    tester,
  ) async {
    await _withSemantics(tester, () async {
      await _pumpCard(tester);

      expect(
        tester.getSemantics(find.byType(ThreadSummaryCard)),
        containsSemantics(isButton: true, hasTapAction: true),
      );
    });
  });
}
