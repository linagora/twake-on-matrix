import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';

class _ConfirmDialogRobot {
  const _ConfirmDialogRobot(this.tester);

  final WidgetTester tester;

  Finder get closeButton => find.descendant(
    of: find.byKey(TwakeDialog.showConfirmAlertDialogKey),
    matching: find.byType(IconButton),
  );

  Future<void> open({required bool showCloseButton}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showConfirmAlertDialog(
              context: context,
              title: 'Delete message',
              message: 'Are you sure?',
              okLabel: 'Delete',
              cancelLabel: 'Cancel',
              showCloseButton: showCloseButton,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('showConfirmAlertDialog close button', () {
    testWidgets('is hidden when showCloseButton is false', (tester) async {
      final robot = _ConfirmDialogRobot(tester);

      await robot.open(showCloseButton: false);

      expect(find.text('Delete message'), findsOneWidget);
      expect(robot.closeButton, findsNothing);
    });

    testWidgets('is shown and dismisses the dialog when showCloseButton is '
        'true', (tester) async {
      final robot = _ConfirmDialogRobot(tester);

      await robot.open(showCloseButton: true);
      expect(robot.closeButton, findsOneWidget);

      await tester.tap(robot.closeButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete message'), findsNothing);
    });
  });
}
