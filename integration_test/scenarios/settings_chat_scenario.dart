import 'package:twake_chat/pages/settings_dashboard/settings/settings_view.dart';

import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/home_robot.dart';
import '../robots/setting/settings_chat_robot.dart';

/// Mobile-only: toggle "GIF autoplay" in Settings > Chat, leave the screen,
/// open it again and verify the new value was persisted. The switch is
/// toggled back at the end so the account keeps its original setting.
///
/// Drives the concrete settings robots directly, so this is registered with
/// `mobileOnly: true`.
class SettingsChatToggleScenario extends BaseTestScenario {
  SettingsChatToggleScenario(super.$, super.robots);

  static const _title = SettingsChatRobot.gifAutoplayTitle;

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();
    final settingRobot = await HomeRobot($).gotoSettingScreen();
    final chatRobot = SettingsChatRobot($);

    await settingRobot.openChatSetting();
    await chatRobot.waitForView();
    await chatRobot.switchTile(_title).waitUntilVisible();

    final initialValue = await chatRobot.waitForStoredValue(_title);

    try {
      await chatRobot.toggleSwitch(_title);
      await chatRobot.backToSettingScreen();
      s.softAssertEquals(
        $(SettingsView).exists,
        true,
        'did not navigate back to Setting View',
      );

      await settingRobot.openChatSetting();
      await chatRobot.waitForView();
      await chatRobot.switchTile(_title).waitUntilVisible();
      s.softAssertEquals(
        await chatRobot.waitForStoredValue(_title),
        !initialValue,
        '"$_title" was not persisted after reopening Settings > Chat',
      );
    } finally {
      // Restore the original value, even if a step above failed.
      if (!chatRobot.view().exists) {
        if (!$(SettingsView).exists) {
          await HomeRobot($).gotoSettingScreen();
        }
        await settingRobot.openChatSetting();
        await chatRobot.waitForView();
      }
      await chatRobot.restoreStoredValue(_title, initialValue);
    }

    s.verifyAll();
  }
}
