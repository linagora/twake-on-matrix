import '../../base/test_base.dart';
import '../../scenarios/chat_group_open_profile_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Chat group open owner profile test',
    scenarioBuilder: ($, robots) => ChatGroupOpenProfileScenario($, robots),
  );
}
