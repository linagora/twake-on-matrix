import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/chat.dart';

void main() {
  const viewportHeight = 600.0;
  const rowHeight = 75.0;
  const targetIndex = 30;

  Widget list(ScrollController controller) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: viewportHeight,
          child: ListView(
            controller: controller,
            cacheExtent: 20000,
            children: [
              for (var i = 0; i < 60; i++)
                SizedBox(key: ValueKey(i), height: rowHeight),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets(
    'the row is at its new position when the scroll completes in one slow frame',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(list(controller));

      const target = targetIndex * rowHeight;
      final row = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey(targetIndex), skipOffstage: false),
      );
      double? dyWhenDone;
      final scroll = scrollAndLayOut(
        controller,
        target,
        duration: const Duration(milliseconds: 250),
      ).then((_) => dyWhenDone = row.localToGlobal(Offset.zero).dy);

      await tester.pump();
      // A frame longer than the animation, as while the search page pops.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await scroll;

      expect(controller.offset, target);
      expect(dyWhenDone, 0.0);
    },
  );
}
