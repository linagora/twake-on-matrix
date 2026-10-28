import '../../base/test_base.dart';
import '../../scenarios/settings_profile_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Profile settings show name, Matrix ID and edit controls, copy the '
        'Matrix ID and go back',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => SettingsProfileOverviewScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Open the avatar menu from profile settings',
    mobileOnly: true,
    scenarioBuilder: ($, robots) =>
        SettingsProfileAvatarMenuScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Open the personal QR code from profile settings',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => SettingsProfileQrCodeScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Open the account picker from profile settings',
    mobileOnly: true,
    scenarioBuilder: ($, robots) =>
        SettingsProfileMultipleAccountsScenario($, robots),
  );
}
