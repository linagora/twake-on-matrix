import '../../base/test_base.dart';
import '../../scenarios/send_message_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Checking sending message between members',
    scenarioBuilder: ($, robots) => SendMessageScenario($, robots),
  );
}
