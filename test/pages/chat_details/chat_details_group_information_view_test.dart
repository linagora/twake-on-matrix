import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat_details/chat_details_group_information_view.dart';

void main() {
  late AnimationController animationController;
  late int tapCount;

  Widget buildWidget() {
    return MaterialApp(
      home: Scaffold(
        body: ChatDetailsGroupInformationView(
          height: 300,
          maxHeight: 400,
          animationController: animationController,
          displayName: 'Group name',
          subTitle: '3 members',
          onTap: () => tapCount++,
        ),
      ),
    );
  }

  setUp(() {
    tapCount = 0;
    animationController = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 250),
    );
  });

  tearDown(() => animationController.dispose());

  group('ChatDetailsGroupInformationView', () {
    testWidgets('tapping the group name does not trigger onTap', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('Group name'));
      await tester.pumpAndSettle();

      expect(tapCount, 0);
    });

    testWidgets('tapping outside the group name triggers onTap', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('3 members'));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    testWidgets('long pressing the group name does not trigger onTap', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.longPress(find.text('Group name'));
      await tester.pumpAndSettle();

      expect(tapCount, 0);
    });
  });
}
