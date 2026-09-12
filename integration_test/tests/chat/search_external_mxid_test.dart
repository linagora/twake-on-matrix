import '../../base/test_base.dart';
import '../../scenarios/external_mxid_search_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Search external contact by Matrix ID validates profile',
    // Resolving an external Matrix ID needs federation / the contact backend,
    // which the isolated local-Synapse harness does not provide (the lookup
    // hangs until timeout).
    requiresBackend: true,
    scenarioBuilder: ($, robots) => ExternalMxidSearchScenario($, robots),
  );
}
