import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/navigation_buttons_safe_area.dart';

void main() {
  const bottomInset = 48.0;
  const childKey = Key('child');

  double screenHeight(WidgetTester tester) =>
      tester.getSize(find.byType(NavigationButtonsSafeArea)).height;

  Future<void> pump(
    WidgetTester tester, {
    required EdgeInsets systemGestureInsets,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: bottomInset),
          ).copyWith(systemGestureInsets: systemGestureInsets),
          child: const NavigationButtonsSafeArea(
            child: SizedBox.expand(key: childKey),
          ),
        ),
      ),
    );
  }

  group('NavigationButtonsSafeArea', () {
    testWidgets('pads the bottom with button navigation on Android', (
      tester,
    ) async {
      await pump(tester, systemGestureInsets: EdgeInsets.zero);

      expect(
        tester.getSize(find.byKey(childKey)).height,
        screenHeight(tester) - bottomInset,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('does not pad with gesture navigation on Android', (
      tester,
    ) async {
      await pump(
        tester,
        systemGestureInsets: const EdgeInsets.symmetric(horizontal: 24),
      );

      expect(tester.getSize(find.byKey(childKey)).height, screenHeight(tester));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('does not pad on iOS', (tester) async {
      await pump(tester, systemGestureInsets: EdgeInsets.zero);

      expect(tester.getSize(find.byKey(childKey)).height, screenHeight(tester));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
