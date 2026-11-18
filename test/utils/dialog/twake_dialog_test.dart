import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';

class _ConfirmDialogRobot {
  _ConfirmDialogRobot(this.tester);

  final WidgetTester tester;

  Future<ConfirmResult>? result;
  int onCloseCalls = 0;

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
            onPressed: () => result = showConfirmAlertDialog(
              context: context,
              title: 'Delete message',
              message: 'Are you sure?',
              okLabel: 'Delete',
              cancelLabel: 'Cancel',
              showCloseButton: showCloseButton,
              onClose: () => onCloseCalls++,
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

    testWidgets('is shown and cancels the dialog when showCloseButton is '
        'true', (tester) async {
      final robot = _ConfirmDialogRobot(tester);

      await robot.open(showCloseButton: true);
      expect(robot.closeButton, findsOneWidget);

      await tester.tap(robot.closeButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete message'), findsNothing);
      expect(await robot.result, ConfirmResult.cancel);
      expect(robot.onCloseCalls, 1);
    });
  });
}
