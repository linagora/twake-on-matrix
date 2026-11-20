import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/chat.dart';

void main() {
  const viewportHeight = 600.0;
  const rowHeight = 75.0;
  const targetKey = ValueKey('target');

  // Laid out like ChatScrollView: older events above the center, events
  // received while the chat is open below it, anchored to the bottom.
  Widget timeline(ScrollController controller) {
    const centerKey = ValueKey('center');
    return MaterialApp(
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: viewportHeight,
          child: CustomScrollView(
            controller: controller,
            center: centerKey,
            anchor: 1,
            cacheExtent: 20000,
            slivers: [
              SliverList.list(
                children: [
                  for (var i = 0; i < 2; i++) const SizedBox(height: rowHeight),
                  const SizedBox(key: targetKey, height: rowHeight),
                  for (var i = 0; i < 10; i++)
                    const SizedBox(height: rowHeight),
                ],
              ),
              SliverList.list(
                key: centerKey,
                children: [
                  for (var i = 0; i < 23; i++)
                    const SizedBox(height: rowHeight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Rect viewportRect(WidgetTester tester) =>
      tester.getRect(find.byType(CustomScrollView));

  testWidgets('centers a row whose sliver is entirely above the viewport', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(timeline(controller));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    final target = tester.renderObject<RenderBox>(
      find.byKey(targetKey, skipOffstage: false),
    );
    final viewport = viewportRect(tester);
    expect(target.localToGlobal(Offset.zero).dy, lessThan(viewport.top));

    controller.jumpTo(offsetToCenter(target, controller.position));
    await tester.pump();

    expect(
      tester.getCenter(find.byKey(targetKey, skipOffstage: false)).dy,
      moreOrLessEquals(viewport.center.dy),
    );
  });
}
