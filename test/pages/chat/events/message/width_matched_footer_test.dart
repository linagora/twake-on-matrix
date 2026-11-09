import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/events/message/width_matched_footer.dart';

/// THR-M-02: the thread card under the text of its root. [WidthMatchedFooter]
/// stacks a body (the text of the root) above a footer (the card). Like the
/// web bubble (fit-content, maintainer reference 09/11): its width is the
/// widest of the body and the natural (max intrinsic) width of the footer,
/// within the constraints; the footer gets that whole width.
void main() {
  const body = Key('body');
  const footer = Key('footer');

  /// A footer whose minimum width is [width]: wider than that it stretches,
  /// narrower it overflows.
  Widget footerOf(double width) => Row(
    key: footer,
    mainAxisSize: MainAxisSize.min,
    children: [SizedBox(width: width, height: 10)],
  );

  Widget matched({double bodyWidth = 50, double footerMinWidth = 120}) =>
      WidthMatchedFooter(
        body: SizedBox(key: body, width: bodyWidth, height: 20),
        footer: footerOf(footerMinWidth),
      );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: Center(child: child),
    ),
  );

  RenderBox renderOf(WidgetTester tester) =>
      tester.renderObject<RenderBox>(find.byType(WidthMatchedFooter));

  /// A footer that can wrap, as the card can cut its last line: its minimum
  /// (longest word) is narrower than its natural width (one line).
  Widget wrappingFooter() => Text(
    '${'a' * 12} ${'b' * 8}',
    key: footer,
    style: const TextStyle(fontSize: 10, height: 1),
  );

  Widget matchedWrapping({double bodyWidth = 50}) => WidthMatchedFooter(
    body: SizedBox(key: body, width: bodyWidth, height: 20),
    footer: wrappingFooter(),
  );

  /// The natural and minimum widths of [wrappingFooter], measured alone.
  Future<({double min, double natural})> footerWidths(
    WidgetTester tester,
  ) async {
    await pump(tester, wrappingFooter());
    final render = tester.renderObject<RenderBox>(find.byKey(footer));
    final widths = (
      min: render.getMinIntrinsicWidth(double.infinity),
      natural: render.getMaxIntrinsicWidth(double.infinity),
    );
    expect(widths.min, lessThan(widths.natural), reason: 'the fixture wraps');
    return widths;
  }

  /// The intrinsic widths say what the layout does: a parent that sizes it
  /// from them (an IntrinsicWidth, a table cell) gets the width it lays out.
  group('width and intrinsic widths', () {
    testWidgets('a footer wider than the body: laid out at the natural width '
        'of the footer', (tester) async {
      final widths = await footerWidths(tester);
      await pump(tester, matchedWrapping(bodyWidth: 50));

      expect(
        tester.getSize(find.byType(WidthMatchedFooter)).width,
        widths.natural,
      );
      expect(tester.getSize(find.byKey(footer)).width, widths.natural);
    });

    testWidgets('a footer wider than the body: min and max intrinsic widths '
        'are those of the footer', (tester) async {
      final widths = await footerWidths(tester);
      await pump(tester, matchedWrapping(bodyWidth: 50));

      expect(
        renderOf(tester).getMinIntrinsicWidth(double.infinity),
        widths.min,
      );
      expect(
        renderOf(tester).getMaxIntrinsicWidth(double.infinity),
        widths.natural,
      );
    });

    testWidgets('a body wider than the footer: width and intrinsic widths are '
        'those of the body', (tester) async {
      await pump(tester, matchedWrapping(bodyWidth: 300));

      expect(tester.getSize(find.byType(WidthMatchedFooter)).width, 300);
      expect(renderOf(tester).getMinIntrinsicWidth(double.infinity), 300);
      expect(renderOf(tester).getMaxIntrinsicWidth(double.infinity), 300);
    });

    testWidgets('less room than the natural width of the footer: it takes '
        'the room it is given, without overflow', (tester) async {
      final widths = await footerWidths(tester);
      final room = (widths.min + widths.natural) / 2;
      await pump(
        tester,
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: room),
          child: matchedWrapping(bodyWidth: 50),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(WidthMatchedFooter)).width, room);
    });

    testWidgets('inside an IntrinsicWidth, the footer gets its natural width '
        'and does not overflow', (tester) async {
      final widths = await footerWidths(tester);
      await pump(tester, IntrinsicWidth(child: matchedWrapping(bodyWidth: 50)));

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(WidthMatchedFooter)).width,
        widths.natural,
      );
    });

    testWidgets('inside an IntrinsicWidth, a footer that cannot wrap does not '
        'overflow', (tester) async {
      await pump(
        tester,
        IntrinsicWidth(child: matched(bodyWidth: 50, footerMinWidth: 120)),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(footer)).width, 120);
    });
  });

  /// THR-M-02, RTL: in a right-to-left language the text of the root and its
  /// card start on the right, as everything else in the bubble.
  group('right to left', () {
    testWidgets('a body narrower than the footer starts on the right', (
      tester,
    ) async {
      await pump(
        tester,
        matched(bodyWidth: 50, footerMinWidth: 120),
        direction: TextDirection.rtl,
      );

      final own = tester.getRect(find.byType(WidthMatchedFooter));
      final text = tester.getRect(find.byKey(body));
      expect(own.width, 120);
      expect(text.right, own.right);
    });

    testWidgets('given more width than it needs, body and footer start on '
        'the right', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 300,
          child: matched(bodyWidth: 50, footerMinWidth: 120),
        ),
        direction: TextDirection.rtl,
      );

      final own = tester.getRect(find.byType(WidthMatchedFooter));
      expect(own.width, 300);
      expect(tester.getRect(find.byKey(body)).right, own.right);
      expect(tester.getRect(find.byKey(footer)).right, own.right);
    });

    testWidgets('left to right, a body narrower than the footer starts on the '
        'left', (tester) async {
      await pump(tester, matched(bodyWidth: 50, footerMinWidth: 120));

      final own = tester.getRect(find.byType(WidthMatchedFooter));
      expect(tester.getRect(find.byKey(body)).left, own.left);
    });
  });
}
