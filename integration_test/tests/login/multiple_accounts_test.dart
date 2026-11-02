import '../../base/test_base.dart';
import '../../scenarios/multiple_accounts_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'add a second account, switch between accounts, log one out and '
        'keep the other active',
    // Drives the native back gesture and the mobile account picker.
    mobileOnly: true,
    scenarioBuilder: ($, robots) => MultipleAccountsScenario($, robots),
  );
}
