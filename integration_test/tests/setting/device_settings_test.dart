import '../../base/test_base.dart';
import '../../scenarios/device_settings_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'List sessions, rename another one, sign it out, then sign out all '
        'other sessions',
    mobileOnly: true,
    requiresDisposableServer: true,
    scenarioBuilder: ($, robots) => DeviceSettingsScenario($, robots),
  );
}
