import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/context_menu/context_menu_action.dart';
import 'package:twake_chat/widgets/context_menu/twake_context_menu.dart';

const _phone = Size(390, 844);

const _folderActions = [
  ContextMenuAction(name: 'Edit folder', icon: Icons.edit_outlined),
  ContextMenuAction(name: 'Delete folder', icon: Icons.delete_outline),
];

const _longAction = [
  ContextMenuAction(
    name: 'An action with a label long enough to reach the max width',
    icon: Icons.edit_outlined,
  ),
];

Future<Rect> _openMenuAt(
  WidgetTester tester,
  Offset position, {
  Size screen = _phone,
  double leftInset = 0,
  List<ContextMenuAction> actions = _folderActions,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(left: leftInset);
  tester.view.viewPadding = FakeViewPadding(left: leftInset);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (dialogContext) => TwakeContextMenu(
                dialogContext: dialogContext,
                position: position,
                listActions: actions,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tester.getRect(find.byType(Card));
}

void main() {
  group('TwakeContextMenu horizontal position', () {
    for (final tapX in [8.0, 40.0, 150.0, 195.0, 300.0, 350.0, 382.0]) {
      testWidgets('stays on screen for a tap at x=$tapX', (tester) async {
        final rect = await _openMenuAt(tester, Offset(tapX, 200));

        expect(rect.left, greaterThanOrEqualTo(8));
        expect(rect.right, lessThanOrEqualTo(_phone.width - 8));
      });
    }

    testWidgets('opens to the right of a tap that leaves enough room', (
      tester,
    ) async {
      final rect = await _openMenuAt(tester, const Offset(40, 200));

      expect(rect.left, 40);
    });

    testWidgets('opens to the left of a tap near the right edge', (
      tester,
    ) async {
      final rect = await _openMenuAt(tester, const Offset(350, 200));

      expect(rect.right, 350);
    });

    testWidgets('anchors a narrow menu at the tap when it fits', (
      tester,
    ) async {
      final rect = await _openMenuAt(
        tester,
        const Offset(230, 200),
        actions: const [ContextMenuAction(name: 'Edit')],
      );

      expect(rect.right, 230);
    });

    testWidgets('stays inside the safe area in landscape', (tester) async {
      final rect = await _openMenuAt(
        tester,
        const Offset(490, 200),
        screen: const Size(800, 390),
        leftInset: 44,
        actions: _longAction,
      );

      expect(rect.left, greaterThanOrEqualTo(44 + 8));
      expect(rect.right, lessThanOrEqualTo(800 - 8));
    });

    testWidgets('shrinks to fit a screen narrower than the max width', (
      tester,
    ) async {
      final rect = await _openMenuAt(
        tester,
        const Offset(2, 200),
        screen: const Size(310, 600),
        actions: _longAction,
      );

      expect(rect.left, greaterThanOrEqualTo(8));
      expect(rect.right, lessThanOrEqualTo(310 - 8));
    });
  });
}
