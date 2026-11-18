import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/default_touch_slop.dart';

void main() {
  Future<List<String>> pumpList(
    WidgetTester tester, {
    double? platformTouchSlop,
  }) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          gestureSettings: DeviceGestureSettings(touchSlop: platformTouchSlop),
        ),
        child: MaterialApp(
          builder: (context, child) => DefaultTouchSlop(child: child!),
          home: Scaffold(
            body: ListView(
              children: [
                for (var i = 0; i < 30; i++)
                  InkWell(
                    key: ValueKey('row$i'),
                    onTap: () => tapped.add('row$i'),
                    child: const SizedBox(height: 80),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return tapped;
  }

  Future<void> flick(WidgetTester tester, double distance) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('row5'))),
    );
    for (var moved = 0.0; moved < distance; moved += 4) {
      await gesture.moveBy(const Offset(0, -4));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  double scrollOffset(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

  testWidgets('a short flick on a row scrolls the list instead of tapping it', (
    tester,
  ) async {
    final tapped = await pumpList(tester);

    await flick(tester, 16);

    expect(tapped, isEmpty);
    expect(scrollOffset(tester), greaterThan(0));
  });

  testWidgets('a tap on a row still taps it', (tester) async {
    final tapped = await pumpList(tester);

    await tester.tap(find.byKey(const ValueKey('row5')));
    await tester.pumpAndSettle();

    expect(tapped, ['row5']);
  });

  testWidgets('keeps the touch slop the platform reports', (tester) async {
    final tapped = await pumpList(tester, platformTouchSlop: 18);

    await flick(tester, 16);

    expect(tapped, ['row5']);
    expect(scrollOffset(tester), 0);
  });
}
