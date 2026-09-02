import 'package:flutter_test/flutter_test.dart';

import '../base/base_test_scenario.dart';
import '../robots/home_robot.dart';
import '../robots/setting/settings_contacts_visibility_robot.dart';
import '../robots/setting/settings_privacy_and_security_robot.dart';

/// Mobile-only: select the "everyone" contacts-visibility option and verify the
/// email/phone fields are hidden. Drives the concrete settings robots directly,
/// so this is registered with `mobileOnly: true`.
class SettingsContactsVisibilityEveryoneScenario extends BaseTestScenario {
  SettingsContactsVisibilityEveryoneScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final settingsRobot = await HomeRobot($).gotoSettingScreen();

    await settingsRobot.openPrivacyAndSecuritySetting();

    await SettingsPrivacyAndSecurityRobot($).openContactVisibilitySetting();

    final contactsVisibilityRobot = SettingsContactsVisibilityRobot($);
    await contactsVisibilityRobot.waitForView();

    // Verify everyone option is present
    await contactsVisibilityRobot.everyoneOption().waitUntilVisible();

    // Select every one option
    await contactsVisibilityRobot.selectEveryoneOption();

    // Wait for UI to settle after selection
    await $.pumpAndSettle();

    // Verify email and phone fields are NOT visible when everyone is selected
    expect(contactsVisibilityRobot.emailFieldOption(), findsNothing);
    expect(contactsVisibilityRobot.phoneNumberFieldOption(), findsNothing);
  }
}

/// Mobile-only: select the "my contacts" contacts-visibility option and verify
/// the email/phone fields become visible. Drives the concrete settings robots
/// directly, so this is registered with `mobileOnly: true`.
class SettingsContactsVisibilityContactsScenario extends BaseTestScenario {
  SettingsContactsVisibilityContactsScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final settingsRobot = await HomeRobot($).gotoSettingScreen();

    await settingsRobot.openPrivacyAndSecuritySetting();

    await SettingsPrivacyAndSecurityRobot($).openContactVisibilitySetting();

    final contactsVisibilityRobot = SettingsContactsVisibilityRobot($);
    await contactsVisibilityRobot.waitForView();

    // Verify contacts option is present
    await contactsVisibilityRobot.contactsOption().waitUntilVisible();

    // Select contacts option
    await contactsVisibilityRobot.selectContactsOption();

    // Wait for UI to settle after selection
    await $.pumpAndSettle();

    // Verify email and phone visible fields are present
    await contactsVisibilityRobot.emailFieldOption().waitUntilVisible();

    await contactsVisibilityRobot.phoneNumberFieldOption().waitUntilVisible();
  }
}

/// Mobile-only: select the "nobody" contacts-visibility option and verify the
/// email/phone fields are hidden. Drives the concrete settings robots directly,
/// so this is registered with `mobileOnly: true`.
class SettingsContactsVisibilityNobodyScenario extends BaseTestScenario {
  SettingsContactsVisibilityNobodyScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final settingsRobot = await HomeRobot($).gotoSettingScreen();

    await settingsRobot.openPrivacyAndSecuritySetting();

    await SettingsPrivacyAndSecurityRobot($).openContactVisibilitySetting();

    final contactsVisibilityRobot = SettingsContactsVisibilityRobot($);
    await contactsVisibilityRobot.waitForView();

    // Verify nobody option is present
    await contactsVisibilityRobot.nobodyOption().waitUntilVisible();

    // Select nobody option
    await contactsVisibilityRobot.selectNobodyOption();

    // Wait for UI to settle after selection
    await $.pumpAndSettle();

    // Verify email and phone fields are NOT visible when nobody is selected
    expect(contactsVisibilityRobot.emailFieldOption(), findsNothing);
    expect(contactsVisibilityRobot.phoneNumberFieldOption(), findsNothing);
  }
}
