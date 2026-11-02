import '../../base/test_base.dart';
import '../../scenarios/create_space_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'create a space and a group inside it',
    scenarioBuilder: ($, robots) => CreateSpaceScenario($, robots),
  );
}
