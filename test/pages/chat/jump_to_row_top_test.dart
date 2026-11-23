import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/chat.dart';

void main() {
  const viewportHeight = 600.0;
  const rowHeight = 75.0;
  const targetKey = ValueKey('unread');

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
            slivers: [
              SliverList.list(
                children: [
                  for (var i = 0; i < 9; i++) const SizedBox(height: rowHeight),
                  const SizedBox(key: targetKey, height: rowHeight),
                  for (var i = 0; i < 20; i++)
                    const SizedBox(height: rowHeight),
                ],
              ),
              SliverList.list(key: centerKey, children: const []),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets(
    'puts the unread row at the top in one frame, without animation',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(timeline(controller));
      final viewport = tester.getRect(find.byType(CustomScrollView));

      final rowContext = tester.element(
        find.byKey(targetKey, skipOffstage: false),
      );
      expect(
        tester.getCenter(find.byKey(targetKey, skipOffstage: false)).dy,
        lessThan(viewport.top),
      );

      jumpToRowTop(controller, rowContext);
      await tester.pump();

      expect(
        tester.getTopLeft(find.byKey(targetKey, skipOffstage: false)).dy,
        moreOrLessEquals(viewport.top),
      );
      expect(controller.position.isScrollingNotifier.value, isFalse);
    },
  );

  testWidgets('does nothing when the row is not laid out', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(timeline(controller));
    final before = controller.offset;

    jumpToRowTop(controller, null);
    await tester.pump();

    expect(controller.offset, before);
  });
}
