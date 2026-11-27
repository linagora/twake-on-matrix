import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/thread/thread_resolved_mark.dart';
import 'package:twake_chat/pages/chat/thread/thread_summary_card.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_summary.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

/// Need (Clément, 2026-11-25, same design as the web, twake-space-chat
/// DECISION.md D800, src/ds/ThreadCard/ThreadCard.tsx): the thread of a root
/// message is ONE row at the very foot of its bubble, a 1 px line above it:
/// the faces of the people who replied (three at most, the most recent
/// first, each once) at 20 px, overlapping slightly with a 2 px ring of the
/// bubble colour; the thread icon in primary; « N comments » in primary,
/// weight 500. No more last reply (author, text, age). Unread: a small
/// primary dot after the label, and said. Resolved: the check stays. The
/// whole row is one button named by its count; the faces are decoration.
void main() {
  group('the count of comments', _countTests);
  group('the faces of the people who replied', _faceTests);
  group('unread and resolved', _unreadResolvedTests);
  group('one button', _buttonTests);
  group('the row in the bubble', _rowTests);
}

final _primary = LinagoraSysColors.material().primary;

/// The colours [MessageBubble] of linagora_design_flutter paints: own
/// messages on the light blue, received ones on white.
final _ownBubble = LinagoraRefColors.material().primary[95]!;
final _receivedBubble = LinagoraSysColors.material().onPrimary;

final _theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: _primary, primary: _primary),
);

const _ana = ThreadReplier(userId: '@ana:example.org', displayName: 'Ana');
const _ben = ThreadReplier(userId: '@ben:example.org', displayName: 'Ben');
const _cid = ThreadReplier(userId: '@cid:example.org', displayName: 'Cid');
const _dan = ThreadReplier(userId: '@dan:example.org', displayName: 'Dan');
const _eve = ThreadReplier(userId: '@eve:example.org', displayName: 'Eve');

/// What a test changes in the row and around it; set by cascade, e.g.
/// `_RowSpec()..unreadCount = 2`.
class _RowSpec {
  int replyCount = 3;
  List<ThreadReplier> repliers = const [_ana, _ben];
  int unreadCount = 0;
  bool isResolved = false;
  bool onOwnBubble = false;
  VoidCallback onTap = () {};
  Locale locale = const Locale('en');
  double maxWidth = 400;
  TextDirection direction = TextDirection.ltr;
}

Future<void> _pumpRow(WidgetTester tester, [_RowSpec? spec]) {
  final row = spec ?? _RowSpec();
  return tester.pumpWidget(
    MaterialApp(
      theme: _theme,
      locale: row.locale,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.supportedLocales,
      home: Scaffold(
        body: Directionality(
          textDirection: row.direction,
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: row.maxWidth,
              child: ThreadSummaryCard(
                replyCount: row.replyCount,
                repliers: row.repliers,
                unreadCount: row.unreadCount,
                isResolved: row.isResolved,
                onOwnBubble: row.onOwnBubble,
                onTap: row.onTap,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final semantics = tester.ensureSemantics();
  await body();
  semantics.dispose();
}

Finder _inRow(Finder matching) =>
    find.descendant(of: find.byType(ThreadSummaryCard), matching: matching);

Finder _label(String text) =>
    _inRow(find.textContaining(text, findRichText: true));

/// The faces, in the order of the tree.
List<Avatar> _faces(WidgetTester tester) =>
    tester.widgetList<Avatar>(_inRow(find.byType(Avatar))).toList();

List<Rect> _faceRects(WidgetTester tester) => [
  for (final element in _inRow(find.byType(Avatar)).evaluate())
    tester.getRect(find.byElementPredicate((e) => e == element)),
];

/// The faces from the start of the row to its end.
List<String?> _faceNamesFromStart(WidgetTester tester, TextDirection dir) {
  final faces = _faces(tester);
  final rects = _faceRects(tester);
  final order = List.generate(faces.length, (i) => i)
    ..sort(
      (a, b) => dir == TextDirection.ltr
          ? rects[a].left.compareTo(rects[b].left)
          : rects[b].right.compareTo(rects[a].right),
    );
  return [for (final i in order) faces[i].name];
}

/// The unread dot: a small primary circle.
Finder _unreadDot() => _inRow(
  find.byWidgetPredicate((widget) {
    final decoration = widget is DecoratedBox ? widget.decoration : null;
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color == _primary;
  }),
);

/// The thread icon: an icon of the row that is neither a face nor the
/// resolved check.
Finder _threadIcon() =>
    find.byType(Icon).filterInRowOutside([Avatar, ResolvedMark]);

extension on Finder {
  /// Only what is in the row and outside every widget of [types].
  Finder filterInRowOutside(List<Type> types) {
    final inRow = _inRow(this);
    return find.byElementPredicate((element) {
      if (!inRow.evaluate().contains(element)) return false;
      var outside = true;
      element.visitAncestorElements((ancestor) {
        if (types.contains(ancestor.widget.runtimeType)) outside = false;
        return outside;
      });
      return outside;
    });
  }
}

/// Every text painted by the row, the faces and the icons left out.
List<String> _rowTexts(WidgetTester tester) => [
  for (final element in find.byType(RichText).filterInRowOutside([
    Avatar,
    Icon,
    ResolvedMark,
  ]).evaluate())
    (element.widget as RichText).text.toPlainText(),
];

/// The 2 px ring around [face]: a circle of [ring] 24 px wide (20 + 2 × 2)
/// that holds the face.
Finder _ringAround(Finder face, Color ring) => find.ancestor(
  of: face,
  matching: find.byWidgetPredicate((widget) {
    final decoration = widget is DecoratedBox ? widget.decoration : null;
    if (decoration is! BoxDecoration) return false;
    final round =
        decoration.shape == BoxShape.circle || decoration.borderRadius != null;
    final border = decoration.border;
    final painted =
        decoration.color == ring ||
        (border is Border && border.top.color == ring);
    return round && painted;
  }),
);

/// The style the count « N comments » is painted with.
TextStyle _countStyle(WidgetTester tester) {
  final text = tester.widget<RichText>(
    find.byType(RichText).filterInRowOutside([
      Avatar,
      Icon,
      ResolvedMark,
    ]).first,
  );
  expect(text.text.toPlainText(), contains('comment'));
  return text.text.style!;
}

/// The line above the row: 1 px, across the whole row, at its top.
bool _hasLineOnTop(WidgetTester tester) {
  final row = tester.getRect(find.byType(ThreadSummaryCard));
  bool spansTop(Rect rect) =>
      (rect.width - row.width).abs() < 0.5 && (rect.top - row.top).abs() < 0.5;
  for (final element in _inRow(find.byType(DecoratedBox)).evaluate()) {
    final decoration = (element.widget as DecoratedBox).decoration;
    final border = decoration is BoxDecoration ? decoration.border : null;
    if (border is! Border) continue;
    final rect = tester.getRect(find.byElementPredicate((e) => e == element));
    if (!spansTop(rect)) continue;
    if (border.top.width == 1 && border.top.color.a > 0) return true;
    // A Divider draws its line as the bottom border of a 1 px box.
    if (rect.height <= 1.5 &&
        border.bottom.width == 1 &&
        border.bottom.color.a > 0) {
      return true;
    }
  }
  for (final element in _inRow(find.byType(ColoredBox)).evaluate()) {
    final rect = tester.getRect(find.byElementPredicate((e) => e == element));
    if (spansTop(rect) && (rect.height - 1).abs() < 0.5) return true;
  }
  return false;
}

void _countTests() {
  testWidgets('says « 3 comments » for three replies', (tester) async {
    await _pumpRow(tester);

    expect(_label('3 comments'), findsOneWidget);
  });

  testWidgets('says « 1 comment » for one reply', (tester) async {
    await _pumpRow(
      tester,
      _RowSpec()
        ..replyCount = 1
        ..repliers = const [_ana],
    );

    expect(_rowTexts(tester), ['1 comment']);
  });

  testWidgets('says « 3 commentaires » in French', (tester) async {
    await _pumpRow(tester, _RowSpec()..locale = const Locale('fr'));

    expect(_rowTexts(tester), ['3 commentaires']);
  });

  testWidgets('says « 1 commentaire » in French for one reply', (tester) async {
    await _pumpRow(
      tester,
      _RowSpec()
        ..locale = const Locale('fr')
        ..replyCount = 1,
    );

    expect(_rowTexts(tester), ['1 commentaire']);
  });

  testWidgets('shows the count alone: no last reply, no author, no age, no '
      'arrow', (tester) async {
    await _pumpRow(tester);

    expect(_rowTexts(tester), ['3 comments']);
  });

  testWidgets('writes the count in the primary colour, weight 500', (
    tester,
  ) async {
    await _pumpRow(tester);

    final style = _countStyle(tester);
    expect(style.color, _primary);
    expect(style.fontWeight, FontWeight.w500);
  });

  group('the size of the count follows the text size setting', () {
    late double factorBefore;
    setUp(() => factorBefore = AppConfig.fontSizeFactor);
    tearDown(() => AppConfig.fontSizeFactor = factorBefore);

    /// The label at [factor] of Settings › text size, as on the web, where it
    /// is rem(13), 13 × the text scale: the body of a text message
    /// (`bodyMedium4` of linagora_design_flutter, 15 px) less 2 px, then
    /// scaled by the setting.
    double labelAt(double factor) =>
        (LinagoraTextStyle.material().bodyMedium4.fontSize! - 2) * factor;

    testWidgets('13 px at the default setting', (tester) async {
      AppConfig.fontSizeFactor = 1;
      await _pumpRow(tester);

      expect(_countStyle(tester).fontSize, labelAt(1));
    });

    testWidgets('grows with the setting: 19.5 px at 1.5', (tester) async {
      AppConfig.fontSizeFactor = 1.5;
      await _pumpRow(tester);

      expect(_countStyle(tester).fontSize, labelAt(1.5));
    });

    testWidgets('shrinks with the setting: 10.4 px at 0.8', (tester) async {
      AppConfig.fontSizeFactor = 0.8;
      await _pumpRow(tester);

      expect(_countStyle(tester).fontSize, moreOrLessEquals(labelAt(0.8)));
    });
  });

  testWidgets('draws the thread icon in primary, between the faces and the '
      'count', (tester) async {
    await _pumpRow(tester);

    expect(_threadIcon(), findsOneWidget);
    final icon = tester.widget<Icon>(_threadIcon());
    final iconColor =
        icon.color ?? IconTheme.of(tester.element(_threadIcon())).color;
    expect(iconColor, _primary);
    final iconRect = tester.getRect(_threadIcon());
    final lastFace = _faceRects(
      tester,
    ).map((r) => r.right).reduce((a, b) => a > b ? a : b);
    expect(iconRect.left, greaterThanOrEqualTo(lastFace));
    expect(
      tester.getRect(_label('3 comments')).left,
      greaterThanOrEqualTo(iconRect.right),
    );
  });
}

void _faceTests() {
  testWidgets('shows the faces given, the most recent replier first, at the '
      'start of the row', (tester) async {
    await _pumpRow(tester, _RowSpec()..repliers = const [_ana, _ben]);

    expect(_faceNamesFromStart(tester, TextDirection.ltr), ['Ana', 'Ben']);
    final firstFace = _faceRects(tester).first;
    expect(firstFace.left, lessThan(tester.getRect(_label('3 comments')).left));
  });

  testWidgets('shows three faces at most, the first three given', (
    tester,
  ) async {
    await _pumpRow(
      tester,
      _RowSpec()
        ..replyCount = 9
        ..repliers = const [_ana, _ben, _cid, _dan, _eve],
    );

    expect(_faceNamesFromStart(tester, TextDirection.ltr), [
      'Ana',
      'Ben',
      'Cid',
    ]);
  });

  testWidgets('shows one face when one person replied', (tester) async {
    await _pumpRow(tester, _RowSpec()..repliers = const [_ana]);

    expect(_faces(tester), hasLength(1));
  });

  testWidgets('shows the count alone when nobody who replied is known', (
    tester,
  ) async {
    await _pumpRow(tester, _RowSpec()..repliers = const []);

    expect(_faces(tester), isEmpty);
    expect(_label('3 comments'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draws each face at 20 px', (tester) async {
    await _pumpRow(tester, _RowSpec()..repliers = const [_ana, _ben, _cid]);

    for (final rect in _faceRects(tester)) {
      expect(rect.size, const Size(20, 20));
    }
  });

  testWidgets('falls back to the Matrix id when a replier has no name', (
    tester,
  ) async {
    await _pumpRow(
      tester,
      _RowSpec()..repliers = const [ThreadReplier(userId: '@zoe:example.org')],
    );

    expect(_faces(tester).single.name, '@zoe:example.org');
  });

  testWidgets('passes the picture of each replier to its face', (tester) async {
    final picture = Uri.parse('mxc://example.org/ana');
    await _pumpRow(
      tester,
      _RowSpec()
        ..repliers = [
          ThreadReplier(
            userId: _ana.userId,
            displayName: 'Ana',
            avatarUrl: picture,
          ),
          _ben,
        ],
    );

    expect(_faces(tester).map((f) => f.mxContent), [picture, null]);
  });

  testWidgets('the faces overlap slightly', (tester) async {
    await _pumpRow(tester, _RowSpec()..repliers = const [_ana, _ben, _cid]);

    final rects = _faceRects(tester)..sort((a, b) => a.left.compareTo(b.left));
    for (var i = 1; i < rects.length; i++) {
      final step = rects[i].left - rects[i - 1].left;
      // Ringed faces are 24 px: a step under 24 overlaps the rings.
      expect(step, lessThan(24), reason: 'face $i does not overlap the last');
      expect(step, greaterThan(10), reason: 'face $i hides the last');
    }
  });

  testWidgets('rings each face with 2 px of the colour of a received bubble', (
    tester,
  ) async {
    await _pumpRow(tester, _RowSpec()..repliers = const [_ana, _ben]);

    for (final element in _inRow(find.byType(Avatar)).evaluate()) {
      final face = find.byElementPredicate((e) => e == element);
      final ring = _ringAround(face, _receivedBubble);
      expect(ring, findsWidgets, reason: 'no ring of the bubble colour');
      expect(tester.getSize(ring.first), const Size(24, 24));
    }
  });

  testWidgets('rings each face with the colour of an own bubble', (
    tester,
  ) async {
    await _pumpRow(
      tester,
      _RowSpec()
        ..onOwnBubble = true
        ..repliers = const [_ana, _ben],
    );

    for (final element in _inRow(find.byType(Avatar)).evaluate()) {
      final face = find.byElementPredicate((e) => e == element);
      final ring = _ringAround(face, _ownBubble);
      expect(ring, findsWidgets, reason: 'no ring of the bubble colour');
      expect(tester.getSize(ring.first), const Size(24, 24));
    }
  });

  testWidgets('right to left, the most recent replier is on the right', (
    tester,
  ) async {
    await _pumpRow(
      tester,
      _RowSpec()
        ..direction = TextDirection.rtl
        ..repliers = const [_ana, _ben],
    );

    expect(_faceNamesFromStart(tester, TextDirection.rtl), ['Ana', 'Ben']);
    expect(
      _faceRects(tester).first.right,
      greaterThan(tester.getRect(_label('3 comments')).right),
    );
  });
}

void _unreadResolvedTests() {
  testWidgets('an unread thread shows an 8 px primary dot after the count', (
    tester,
  ) async {
    await _pumpRow(tester, _RowSpec()..unreadCount = 2);

    expect(_unreadDot(), findsOneWidget);
    expect(tester.getSize(_unreadDot()), const Size(8, 8));
    expect(
      tester.getRect(_unreadDot()).left,
      greaterThanOrEqualTo(tester.getRect(_label('3 comments')).right),
    );
  });

  testWidgets('right to left, the dot is on the left of the count', (
    tester,
  ) async {
    await _pumpRow(
      tester,
      _RowSpec()
        ..unreadCount = 2
        ..direction = TextDirection.rtl,
    );

    expect(
      tester.getRect(_unreadDot()).right,
      lessThanOrEqualTo(tester.getRect(_label('3 comments')).left),
    );
  });

  testWidgets('a read thread shows no dot', (tester) async {
    await _pumpRow(tester);

    expect(_unreadDot(), findsNothing);
  });

  testWidgets('says how many replies are unread', (tester) async {
    await _withSemantics(tester, () async {
      await _pumpRow(tester, _RowSpec()..unreadCount = 2);

      expect(
        find.bySemanticsLabel(RegExp('3 comments.*2 unread messages')),
        findsOneWidget,
      );
    });
  });

  testWidgets('says nothing unread once the thread is read', (tester) async {
    await _withSemantics(tester, () async {
      await _pumpRow(tester);

      expect(find.bySemanticsLabel(RegExp('unread')), findsNothing);
    });
  });

  testWidgets('a resolved thread keeps its check, and says it', (tester) async {
    await _withSemantics(tester, () async {
      await _pumpRow(tester, _RowSpec()..isResolved = true);

      expect(_inRow(find.byType(ResolvedMark)), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('3 comments.*Resolved')),
        findsOneWidget,
      );
    });
  });

  testWidgets('an open thread has no check', (tester) async {
    await _pumpRow(tester);

    expect(_inRow(find.byType(ResolvedMark)), findsNothing);
  });

  testWidgets('a narrow bubble with every part never overflows', (
    tester,
  ) async {
    await _pumpRow(
      tester,
      _RowSpec()
        ..maxWidth = 160
        ..replyCount = 1200
        ..repliers = const [_ana, _ben, _cid]
        ..unreadCount = 12
        ..isResolved = true,
    );

    expect(tester.takeException(), isNull);
  });
}

void _buttonTests() {
  testWidgets('is one button named by its count: the faces are decoration', (
    tester,
  ) async {
    await _withSemantics(tester, () async {
      await _pumpRow(tester, _RowSpec()..repliers = const [_ana, _ben]);

      expect(find.bySemanticsLabel('3 comments'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Ana|Ben')), findsNothing);
      expect(
        tester.getSemantics(find.byType(ThreadSummaryCard)),
        containsSemantics(isButton: true, hasTapAction: true),
      );
    });
  });

  testWidgets('a press on the count opens the thread', (tester) async {
    var opened = 0;
    await _pumpRow(tester, _RowSpec()..onTap = () => opened++);

    await tester.tap(_label('3 comments'));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('a press on a face opens the thread', (tester) async {
    var opened = 0;
    await _pumpRow(tester, _RowSpec()..onTap = () => opened++);

    await tester.tap(_inRow(find.byType(Avatar)).first);
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('opens with the keyboard alone', (tester) async {
    var opened = 0;
    await _pumpRow(tester, _RowSpec()..onTap = () => opened++);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(opened, 1);
  });
}

void _rowTests() {
  testWidgets('has a 1 px line across its top', (tester) async {
    await _pumpRow(tester);

    expect(_hasLineOnTop(tester), isTrue);
  });

  testWidgets('takes the whole width it is given', (tester) async {
    await _pumpRow(tester, _RowSpec()..maxWidth = 500);

    expect(tester.getSize(find.byType(ThreadSummaryCard)).width, 500);
  });
}
