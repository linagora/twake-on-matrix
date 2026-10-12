import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/twake_cupertino_page.dart';

void main() {
  Future<void> pumpPushedPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              TwakeCupertinoPageRoute(builder: (_) => const Text('pushed')),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('pushed'), findsOneWidget);
  }

  testWidgets('pops when swiping from inside the back gesture area', (
    tester,
  ) async {
    await pumpPushedPage(tester);

    await tester.dragFrom(
      const Offset(kTwakeBackGestureWidth - 10, 300),
      const Offset(600, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('pushed'), findsNothing);
  });

  testWidgets('stays when swiping from outside the back gesture area', (
    tester,
  ) async {
    await pumpPushedPage(tester);

    await tester.dragFrom(
      const Offset(kTwakeBackGestureWidth + 10, 300),
      const Offset(600, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('pushed'), findsOneWidget);
  });
}
