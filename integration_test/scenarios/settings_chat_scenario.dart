import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings_view.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/home_robot.dart';
import '../robots/setting/settings_chat_robot.dart';

/// Mobile-only: toggle "GIF autoplay" in Settings > Chat and verify the new
/// value reaches `AppConfig` and the real storage key, leave the screen, open
/// it again and verify the value was persisted, then toggle it back through
/// the switch so the account keeps its original setting.
///
/// Drives the concrete settings robots directly, so this is registered with
/// `mobileOnly: true`.
class SettingsChatToggleScenario extends BaseTestScenario {
  SettingsChatToggleScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();
    final settingRobot = await HomeRobot($).gotoSettingScreen();
    final chatRobot = SettingsChatRobot($);

    await settingRobot.openChatSetting();
    await chatRobot.waitForView();
    final title = chatRobot.gifAutoplayTitle;
    await chatRobot.switchTile(title).waitUntilVisible();

    // The expectation comes from the storage key the app reads at startup,
    // not from the tile under test.
    final initialValue = await Store().getItemBool(
      SettingKeys.gifAutoplay,
      AppConfig.gifAutoplay,
    );
    Future<void> verifyApplied(bool expected, String step) async {
      s.softAssertEquals(
        AppConfig.gifAutoplay,
        expected,
        'AppConfig.gifAutoplay did not follow the switch $step',
      );
      s.softAssertEquals(
        await Store().getItemBool(SettingKeys.gifAutoplay, !expected),
        expected,
        '"$title" was not stored under SettingKeys.gifAutoplay $step',
      );
    }

    await chatRobot.toggleSwitch(title, from: initialValue);
    await verifyApplied(!initialValue, 'after the first toggle');
    await chatRobot.backToSettingScreen();
    s.softAssertEquals(
      $(SettingsView).exists,
      true,
      'did not navigate back to Setting View',
    );

    // The tile defaults to `AppConfig.gifAutoplay`, which the first toggle
    // already changed: reset it so only a real read of the store can show the
    // persisted value when the screen is opened again.
    AppConfig.gifAutoplay = initialValue;
    await settingRobot.openChatSetting();
    await chatRobot.waitForView();
    await chatRobot.waitForSwitchValue(title, !initialValue);

    // Toggling back through the switch also leaves the account as it was.
    await chatRobot.toggleSwitch(title, from: !initialValue);
    await verifyApplied(initialValue, 'after toggling back');

    s.verifyAll();
  }
}
