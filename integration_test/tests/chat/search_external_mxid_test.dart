import '../../base/test_base.dart';
import '../../scenarios/external_mxid_search_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Search external contact by Matrix ID validates profile',
    scenarioBuilder: ($, robots) => ExternalMxidSearchScenario($, robots),
  );
}
