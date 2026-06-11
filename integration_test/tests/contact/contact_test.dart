import '../../base/test_base.dart';
import '../../scenarios/contact_search_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'searching a contact',
    scenarioBuilder: ($, robots) => ContactSearchScenario($, robots),
  );
}
