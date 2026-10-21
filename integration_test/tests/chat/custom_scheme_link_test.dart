import '../../base/test_base.dart';
import '../../scenarios/custom_scheme_link_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Custom scheme links are handed to the OS as-is',
    // Mobile-only: on web the browser does not report whether a custom scheme
    // was handled, so the scenario has nothing to assert.
    mobileOnly: true,
    scenarioBuilder: ($, robots) => CustomSchemeLinkScenario($, robots),
  );
}
