import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:twake_chat/pages/chat/chat_web_scrollbar.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

final Finder _scrollbarFinder = find.byType(ChatWebScrollbar);

ListView _tallList(ScrollController controller, String prefix) => ListView(
  controller: controller,
  children: List.generate(
    50,
    (i) => SizedBox(height: 40, child: Text('$prefix$i')),
  ),
);

ChatWebScrollbarState _state(WidgetTester tester) {
  return tester.state<ChatWebScrollbarState>(_scrollbarFinder);
}

Future<void> _dragThumb(WidgetTester tester, Offset delta) async {
  final thumbRect = _state(tester).debugThumbGlobalRect();
  expect(thumbRect, isNotNull);
  await tester.dragFrom(thumbRect!.center, delta);
}

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

  testWidgets(
    'thumb drag maps absolute pointer movement to scroll offset',
    _thumbDragMapsAbsolutely,
  );

  testWidgets(
    'thumb drag to the bottom reaches maxScrollExtent',
    _thumbDragToBottomReachesMaxExtent,
  );

  testWidgets(
    'wheel scroll does not rebuild the scrollable child tree',
    _wheelScrollDoesNotRebuildChild,
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
  expect(_state(tester).debugHasScrollableThumb, isFalse);
  expect(_state(tester).debugThumbGlobalRect(), isNull);
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
  // scroll position" and does not arm gestures instead of crashing.
  expect(_state(tester).debugHasScrollableThumb, isFalse);
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
  // Let the initial ScrollMetricsNotification arm the painter / gestures.
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(_state(tester).debugHasScrollableThumb, isTrue);
  expect(_state(tester).debugThumbGlobalRect(), isNotNull);
}

Future<void> _thumbDragMapsAbsolutely(WidgetTester tester) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    _wrap(
      SizedBox(
        width: 300,
        height: 200,
        child: ChatWebScrollbar(
          controller: controller,
          child: _tallList(controller, 'd'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(_state(tester).debugHasScrollableThumb, isTrue);
  expect(controller.offset, 0.0);

  // Drag the thumb downward. Absolute mapping should advance scroll offset
  // roughly in proportion to pointer travel along the track.
  await _dragThumb(tester, const Offset(0, 80));
  await tester.pumpAndSettle();

  expect(controller.offset, greaterThan(0.0));
  expect(controller.offset, lessThan(controller.position.maxScrollExtent));
  expect(tester.takeException(), isNull);
}

Future<void> _thumbDragToBottomReachesMaxExtent(WidgetTester tester) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    _wrap(
      SizedBox(
        width: 300,
        height: 200,
        child: ChatWebScrollbar(
          controller: controller,
          child: _tallList(controller, 'e'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // A large downward drag should clamp to the end of the scroll range.
  await _dragThumb(tester, const Offset(0, 2000));
  await tester.pumpAndSettle();

  expect(controller.offset, controller.position.maxScrollExtent);
  expect(tester.takeException(), isNull);
}

Future<void> _wheelScrollDoesNotRebuildChild(WidgetTester tester) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);

  var childBuilds = 0;
  await tester.pumpWidget(
    _wrap(
      SizedBox(
        width: 300,
        height: 200,
        child: ChatWebScrollbar(
          controller: controller,
          child: Builder(
            builder: (context) {
              childBuilds++;
              return _tallList(controller, 'f');
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final buildsAfterLayout = childBuilds;
  expect(buildsAfterLayout, greaterThan(0));

  // Simulate content scrolling by jumping the controller. A paint-based
  // scrollbar must update the thumb without rebuilding [child].
  controller.jumpTo(120);
  await tester.pump();
  controller.jumpTo(240);
  await tester.pump();

  expect(childBuilds, buildsAfterLayout);
  expect(tester.takeException(), isNull);
}
