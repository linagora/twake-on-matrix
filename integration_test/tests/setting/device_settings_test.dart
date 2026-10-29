import '../../base/test_base.dart';
import '../../scenarios/device_settings_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'List the current and another session, rename the other one, then '
        'sign it out',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => DeviceSettingsScenario($, robots),
  );
}
