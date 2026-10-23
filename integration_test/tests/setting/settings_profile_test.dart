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
    description: 'Back from profile settings returns to settings',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => SettingsProfileBackScenario($, robots),
  );
}
