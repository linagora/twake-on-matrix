import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/adaptive_scaffold_appbar.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/adaptive_scaffold_appbar_style.dart';

void main() {
  testWidgets('renders on a wide non-web screen without throwing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdaptiveScaffoldAppBar())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(AdaptiveScaffoldAppBarStyle.adaptiveAppBarKey),
      findsOneWidget,
    );
  });
}
