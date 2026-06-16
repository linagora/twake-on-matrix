import '../../base/test_base.dart';
import '../../scenarios/settings_contacts_visibility_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Open settings contact visibility screen test and verify everyone option is present',
    mobileOnly: true,
    scenarioBuilder: ($, robots) =>
        SettingsContactsVisibilityEveryoneScenario($, robots),
  );

  TestBase().runPatrolTest(
    description:
        'Open settings contact visibility screen test and my contacts option is present',
    mobileOnly: true,
    scenarioBuilder: ($, robots) =>
        SettingsContactsVisibilityContactsScenario($, robots),
  );

  TestBase().runPatrolTest(
    description:
        'Open settings contact visibility screen test and nobody option is present',
    mobileOnly: true,
    scenarioBuilder: ($, robots) =>
        SettingsContactsVisibilityNobodyScenario($, robots),
  );
}
