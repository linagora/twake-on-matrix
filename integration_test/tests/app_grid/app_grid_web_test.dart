import '../../base/test_base.dart';
import '../../scenarios/app_grid_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'App grid opens with the configured apps and closes',
    webOnly: true,
    scenarioBuilder: ($, robots) => AppGridOpenAndCloseScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'App grid closes when tapping outside',
    webOnly: true,
    scenarioBuilder: ($, robots) => AppGridCloseOnTapOutsideScenario($, robots),
  );
}
