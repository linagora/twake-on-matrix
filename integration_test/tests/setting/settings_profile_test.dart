import '../../base/test_base.dart';
import '../../scenarios/settings_profile_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Open profile settings and see display name and Matrix ID',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => SettingsProfileOpenScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Profile settings show edit controls allowed by capabilities',
    mobileOnly: true,
    scenarioBuilder: ($, robots) =>
        SettingsProfileCapabilitiesScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Copy Matrix ID from profile settings',
    mobileOnly: true,
    scenarioBuilder: ($, robots) =>
        SettingsProfileCopyMatrixIdScenario($, robots),
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

  TestBase().runPatrolTest(
    description: 'Back from profile settings returns to settings',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => SettingsProfileBackScenario($, robots),
  );
}
