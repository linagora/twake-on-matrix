import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../base/test_base.dart';
import '../../robots/home_robot.dart';
import '../../robots/setting/setting_robot.dart';
import '../../robots/setting/settings_recovery_key_robot.dart';

void main() {
  TestBase().twakePatrolTest(
    description:
        'Copy recovery key and verify clipboard contains the actual key',
    test: ($) async {
      // Clear clipboard before test
      await Clipboard.setData(const ClipboardData(text: ''));

      // Navigate to Settings > Privacy and Security
      await HomeRobot($).gotoSettingScreen();
      await SettingRobot($).openPrivacyAndSecuritySetting();

      final recoveryKeyRobot = SettingsRecoveryKeyRobot($);

      // Verify recovery key item is visible
      await recoveryKeyRobot.waitForRecoveryKeyVisible();

      // Tap the copy button and confirm the warning dialog
      await recoveryKeyRobot.tapCopyAndConfirm();

      // Verify the snackbar confirmation is shown
      await recoveryKeyRobot.verifySnackBarIsShown();

      // Read clipboard content and verify it contains the actual key
      final clipboardText = await recoveryKeyRobot.getClipboardText();

      expect(
        clipboardText,
        isNotNull,
        reason: 'Clipboard should contain the recovery key after copy',
      );
      expect(
        clipboardText,
        isNotEmpty,
        reason: 'Recovery key in clipboard should not be empty',
      );
      // Ensure the clipboard contains the real key, not the masked bullets
      expect(
        clipboardText,
        isNot(equals('\u2022' * 32)),
        reason:
            'Clipboard should contain the actual recovery key, not the masked value',
      );
    },
  );
}
