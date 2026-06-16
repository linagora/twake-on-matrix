import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluffychat/pages/chat/chat_web_scrollbar.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// The scrollbar thumb is the only `MouseRegion` using the grab cursor, so its
// presence/absence is a precise signal for "is the scrollbar track shown".
final Finder _thumbFinder = find.byWidgetPredicate(
  (w) => w is MouseRegion && w.cursor == SystemMouseCursors.grab,
);

ListView _tallList(ScrollController controller, String prefix) => ListView(
  controller: controller,
  children: List.generate(
    50,
    (i) => SizedBox(height: 40, child: Text('$prefix$i')),
  ),
);

void main() {
  testWidgets(
    'renders child and shows no thumb when no scroll view is attached',
    _noScrollViewAttached,
  );

  testWidgets(
    'does not trip the `_positions.length == 1` assertion when the controller '
    'is attached to multiple scroll views',
    _multipleScrollViewsAttached,
  );

  testWidgets(
    'shows the thumb when exactly one scrollable view is attached',
    _singleScrollViewAttached,
  );
}

Future<void> _noScrollViewAttached(WidgetTester tester) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    _wrap(
      ChatWebScrollbar(
        controller: controller,
        child: const SizedBox(width: 100, height: 100),
      ),
    ),
  );

  expect(tester.takeException(), isNull);
  expect(_thumbFinder, findsNothing);
}

Future<void> _multipleScrollViewsAttached(WidgetTester tester) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);

  // Two scrollables sharing one controller -> `controller.positions.length` is
  // 2, which is the transient state that occurs on web while entering message
  // multi-select mode.
  await tester.pumpWidget(
    _wrap(
      Column(
        children: [
          Expanded(
            child: ChatWebScrollbar(
              controller: controller,
              child: _tallList(controller, 'a'),
            ),
          ),
          Expanded(child: _tallList(controller, 'b')),
        ],
      ),
    ),
  );

  expect(tester.takeException(), isNull);
  // With more than one attached position the scrollbar treats it as "no single
  // scroll position" and renders no thumb instead of crashing.
  expect(_thumbFinder, findsNothing);
}

Future<void> _singleScrollViewAttached(WidgetTester tester) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    _wrap(
      SizedBox(
        height: 200,
        child: ChatWebScrollbar(
          controller: controller,
          child: _tallList(controller, 'c'),
        ),
      ),
    ),
  );
  // Let the initial ScrollMetricsNotification rebuild the thumb.
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(_thumbFinder, findsOneWidget);
}
