import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../base/base_test_scenario.dart';
import '../robots/home_robot.dart';
import '../robots/setting/setting_robot.dart';
import '../robots/setting/settings_recovery_key_robot.dart';

/// Mobile-only: copy the recovery key and verify the system clipboard contains
/// the real key (not the masked bullets). Reads the clipboard via concrete
/// robots, so this is registered with `mobileOnly: true`.
class SettingsRecoveryKeyScenario extends BaseTestScenario {
  SettingsRecoveryKeyScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    // Clear clipboard before test
    await Clipboard.setData(const ClipboardData(text: ''));

    // Navigate to Settings > Privacy and Security
    await HomeRobot($).gotoSettingScreen();
    await SettingRobot($).openPrivacyAndSecuritySetting();

    final recoveryKeyRobot = SettingsRecoveryKeyRobot($);

    // Verify recovery key item is visible. It is only rendered when the ToM
    // server returns recovery words for the account; CI accounts provisioned
    // without them get a 404 and the section stays hidden. That is an
    // environment precondition, so skip instead of failing the nightly.
    final recoveryKeyVisible = await recoveryKeyRobot
        .waitForRecoveryKeyVisibleOrNull();
    if (!recoveryKeyVisible) {
      // ignore: avoid_print
      print(
        'Recovery key item not shown: no recovery words for this ToM '
        'account (GET /_twake/recoveryWords → 404). Skipping copy assertions.',
      );
      return;
    }

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
      isNot(equals('•' * 32)),
      reason:
          'Clipboard should contain the actual recovery key, not the masked value',
    );
  }
}
