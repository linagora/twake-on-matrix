import '../../base/test_base.dart';
import '../../robots/home_robot.dart';
import '../../robots/setting/settings_contacts_visibility_robot.dart';
import '../../robots/setting/settings_privacy_and_security_robot.dart';

void main() {
  TestBase().twakePatrolTest(
    description:
        'Open settings contact visibility screen test and verify everyone option is present',
    test: ($) async {
      final settingsRobot = await HomeRobot($).gotoSettingScreen();

      await settingsRobot.openPrivacyAndSecuritySetting();

      await SettingsPrivacyAndSecurityRobot($).openContactVisibilitySetting();

      final contactsVisibilityRobot = SettingsContactsVisibilityRobot($);
      await contactsVisibilityRobot.waitForView();

      // Verify everyone option is present
      await contactsVisibilityRobot.everyoneOption().waitUntilVisible();
    },
  );

  TestBase().twakePatrolTest(
    description:
        'Open settings contact visibility screen test and my contacts option is present',
    test: ($) async {
      final settingsRobot = await HomeRobot($).gotoSettingScreen();

      await settingsRobot.openPrivacyAndSecuritySetting();

      await SettingsPrivacyAndSecurityRobot($).openContactVisibilitySetting();

      final contactsVisibilityRobot = SettingsContactsVisibilityRobot($);
      await contactsVisibilityRobot.waitForView();

      // Verify contacts option is present
      await contactsVisibilityRobot.contactsOption().waitUntilVisible();

      /// Verify email and phone visible fields are present

      await contactsVisibilityRobot.emailFieldOption().waitUntilVisible();

      await contactsVisibilityRobot.phoneNumberFieldOption().waitUntilVisible();
    },
  );

  TestBase().twakePatrolTest(
    description:
        'Open settings contact visibility screen test and nobody option is present',
    test: ($) async {
      final settingsRobot = await HomeRobot($).gotoSettingScreen();

      await settingsRobot.openPrivacyAndSecuritySetting();

      await SettingsPrivacyAndSecurityRobot($).openContactVisibilitySetting();

      final contactsVisibilityRobot = SettingsContactsVisibilityRobot($);
      await contactsVisibilityRobot.waitForView();

      // Verify nobody option is present
      await contactsVisibilityRobot.nobodyOption().waitUntilVisible();
    },
  );
}
