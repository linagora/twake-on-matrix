import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/context_menu/context_menu_action.dart';
import 'package:twake_chat/widgets/context_menu/twake_context_menu.dart';

const _screenSize = Size(390, 844);

Future<Rect> _openMenuAt(WidgetTester tester, Offset position) async {
  tester.view.physicalSize = _screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TwakeContextMenu(
          dialogContext: context,
          position: position,
          listActions: const [
            ContextMenuAction(name: 'Edit folder', icon: Icons.edit_outlined),
            ContextMenuAction(
              name: 'Delete folder',
              icon: Icons.delete_outline,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.getRect(find.byType(Card));
}

void main() {
  group('TwakeContextMenu horizontal position', () {
    for (final tapX in [8.0, 40.0, 150.0, 195.0, 300.0, 350.0, 382.0]) {
      testWidgets('stays on screen for a tap at x=$tapX', (tester) async {
        final rect = await _openMenuAt(tester, Offset(tapX, 200));

        expect(rect.left, greaterThanOrEqualTo(8));
        expect(rect.right, lessThanOrEqualTo(_screenSize.width - 8));
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
  });
}
