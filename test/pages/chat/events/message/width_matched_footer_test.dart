import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/events/message/width_matched_footer.dart';

/// THR-M-02: the thread card under the text of its root. [WidthMatchedFooter]
/// stacks a body (the text of the root) above a footer (the card). Like the
/// web bubble (fit-content, maintainer reference 09/11): its width is the
/// widest of the body and the natural (max intrinsic) width of the footer,
/// within the constraints; the footer gets that whole width.
void main() {
  /// The intrinsic widths say what the layout does: a parent that sizes it
  /// from them (an IntrinsicWidth, a table cell) gets the width it lays out.
  group('width and intrinsic widths', _widthTests);

  /// THR-M-02, RTL: in a right-to-left language the text of the root and its
  /// card start on the right, as everything else in the bubble.
  group('right to left', _directionTests);
}

const _body = Key('body');
const _footer = Key('footer');

Widget _bodyOf(double width) => SizedBox(key: _body, width: width, height: 20);

/// A footer whose minimum width is [width]: wider than that it stretches,
/// narrower it overflows.
Widget _matched({double bodyWidth = 50, double footerMinWidth = 120}) =>
    WidthMatchedFooter(
      body: _bodyOf(bodyWidth),
      footer: Row(
        key: _footer,
        mainAxisSize: MainAxisSize.min,
        children: [SizedBox(width: footerMinWidth, height: 10)],
      ),
    );

/// A footer that can wrap, as the card can cut its last line: its minimum
/// (longest word) is narrower than its natural width (one line).
Widget _wrappingFooter() => Text(
  '${'a' * 12} ${'b' * 8}',
  key: _footer,
  style: const TextStyle(fontSize: 10, height: 1),
);

Widget _matchedWrapping({double bodyWidth = 50}) =>
    WidthMatchedFooter(body: _bodyOf(bodyWidth), footer: _wrappingFooter());

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) => tester.pumpWidget(
  Directionality(
    textDirection: direction,
    child: Center(child: child),
  ),
);

RenderBox _renderOf(WidgetTester tester) =>
    tester.renderObject<RenderBox>(find.byType(WidthMatchedFooter));

Rect _ownRect(WidgetTester tester) =>
    tester.getRect(find.byType(WidthMatchedFooter));

double _ownWidth(WidgetTester tester) => _ownRect(tester).width;

/// The min and max intrinsic widths of the [WidthMatchedFooter].
(double, double) _intrinsicWidths(WidgetTester tester) => (
  _renderOf(tester).getMinIntrinsicWidth(double.infinity),
  _renderOf(tester).getMaxIntrinsicWidth(double.infinity),
);

/// The natural and minimum widths of [_wrappingFooter], measured alone.
Future<({double min, double natural})> _footerWidths(
  WidgetTester tester,
) async {
  await _pump(tester, _wrappingFooter());
  final render = tester.renderObject<RenderBox>(find.byKey(_footer));
  final widths = (
    min: render.getMinIntrinsicWidth(double.infinity),
    natural: render.getMaxIntrinsicWidth(double.infinity),
  );
  expect(widths.min, lessThan(widths.natural), reason: 'the fixture wraps');
  return widths;
}

void _widthTests() {
  testWidgets('a footer wider than the body: laid out at the natural width '
      'of the footer', (tester) async {
    final widths = await _footerWidths(tester);
    await _pump(tester, _matchedWrapping(bodyWidth: 50));

    expect(_ownWidth(tester), widths.natural);
    expect(tester.getSize(find.byKey(_footer)).width, widths.natural);
  });

  testWidgets('a footer wider than the body: min and max intrinsic widths '
      'are those of the footer', (tester) async {
    final widths = await _footerWidths(tester);
    await _pump(tester, _matchedWrapping(bodyWidth: 50));

    expect(_intrinsicWidths(tester), (widths.min, widths.natural));
  });

  testWidgets('a body wider than the footer: width and intrinsic widths are '
      'those of the body', (tester) async {
    await _pump(tester, _matchedWrapping(bodyWidth: 300));

    expect(_ownWidth(tester), 300);
    expect(_intrinsicWidths(tester), (300, 300));
  });

  testWidgets('less room than the natural width of the footer: it takes '
      'the room it is given, without overflow', (tester) async {
    final widths = await _footerWidths(tester);
    final room = (widths.min + widths.natural) / 2;
    await _pump(
      tester,
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: room),
        child: _matchedWrapping(bodyWidth: 50),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_ownWidth(tester), room);
  });

  testWidgets('inside an IntrinsicWidth, the footer gets its natural width '
      'and does not overflow', (tester) async {
    final widths = await _footerWidths(tester);
    await _pump(tester, IntrinsicWidth(child: _matchedWrapping(bodyWidth: 50)));

    expect(tester.takeException(), isNull);
    expect(_ownWidth(tester), widths.natural);
  });

  testWidgets('inside an IntrinsicWidth, a footer that cannot wrap does not '
      'overflow', (tester) async {
    await _pump(
      tester,
      IntrinsicWidth(child: _matched(bodyWidth: 50, footerMinWidth: 120)),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(_footer)).width, 120);
  });
}

void _directionTests() {
  testWidgets('a body narrower than the footer starts on the right', (
    tester,
  ) async {
    await _pump(
      tester,
      _matched(bodyWidth: 50, footerMinWidth: 120),
      direction: TextDirection.rtl,
    );

    final own = _ownRect(tester);
    expect(own.width, 120);
    expect(tester.getRect(find.byKey(_body)).right, own.right);
  });

  testWidgets('given more width than it needs, body and footer start on '
      'the right', (tester) async {
    await _pump(
      tester,
      SizedBox(width: 300, child: _matched(bodyWidth: 50, footerMinWidth: 120)),
      direction: TextDirection.rtl,
    );

    final own = _ownRect(tester);
    expect(own.width, 300);
    expect(tester.getRect(find.byKey(_body)).right, own.right);
    expect(tester.getRect(find.byKey(_footer)).right, own.right);
  });

  testWidgets('left to right, a body narrower than the footer starts on the '
      'left', (tester) async {
    await _pump(tester, _matched(bodyWidth: 50, footerMinWidth: 120));

    expect(tester.getRect(find.byKey(_body)).left, _ownRect(tester).left);
  });
}
