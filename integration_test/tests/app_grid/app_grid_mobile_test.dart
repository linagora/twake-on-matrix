import '../../base/test_base.dart';
import '../../scenarios/app_grid_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'App grid is not shown on mobile',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => AppGridHiddenScenario($, robots),
  );
}
