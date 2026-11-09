import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/events/message/width_matched_footer.dart';

/// THR-M-02: the thread card under the text of its root. [WidthMatchedFooter]
/// stacks a body (the text of the root) above a footer (the card): the
/// footer is as wide as the body, unless its own minimum is wider.
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

  /// The intrinsic widths say what the layout does: a parent that sizes it
  /// from them (an IntrinsicWidth, a table cell) gets the width it lays out.
  group('intrinsic widths', () {
    testWidgets('a footer wider than the body: both intrinsic widths are the '
        'footer minimum', (tester) async {
      await pump(tester, matched(bodyWidth: 50, footerMinWidth: 120));

      expect(renderOf(tester).getMinIntrinsicWidth(double.infinity), 120);
      expect(renderOf(tester).getMaxIntrinsicWidth(double.infinity), 120);
    });

    testWidgets('a body wider than the footer: both intrinsic widths are the '
        'body ones', (tester) async {
      await pump(tester, matched(bodyWidth: 200, footerMinWidth: 120));

      expect(renderOf(tester).getMinIntrinsicWidth(double.infinity), 200);
      expect(renderOf(tester).getMaxIntrinsicWidth(double.infinity), 200);
    });

    testWidgets('inside an IntrinsicWidth, the footer gets its minimum and '
        'does not overflow', (tester) async {
      await pump(
        tester,
        IntrinsicWidth(child: matched(bodyWidth: 50, footerMinWidth: 120)),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(WidthMatchedFooter)).width, 120);
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
