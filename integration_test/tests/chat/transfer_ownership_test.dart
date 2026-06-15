import '../../base/test_base.dart';
import '../../scenarios/transfer_ownership_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    tags: ['transfer_ownership_test_01'],
    description:
        'Transfer ownership button disappears after successful transfer',
    scenarioBuilder: ($, robots) => TransferOwnershipScenario($, robots),
  );
}
