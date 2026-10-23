import '../../base/test_base.dart';
import '../../scenarios/settings_profile_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Open profile settings and see display name and Matrix ID',
    webOnly: true,
    scenarioBuilder: ($, robots) => SettingsProfileOpenScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Profile settings show edit controls allowed by capabilities',
    webOnly: true,
    scenarioBuilder: ($, robots) =>
        SettingsProfileCapabilitiesScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Open the avatar menu from profile settings',
    webOnly: true,
    scenarioBuilder: ($, robots) =>
        SettingsProfileAvatarMenuScenario($, robots),
  );
}
