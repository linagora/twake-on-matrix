import '../../base/test_base.dart';
import '../../scenarios/settings_recovery_key_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Copy recovery key and verify clipboard contains the actual key',
    // Mobile-only: reads the system clipboard via concrete robots.
    mobileOnly: true,
    scenarioBuilder: ($, robots) => SettingsRecoveryKeyScenario($, robots),
  );
}
