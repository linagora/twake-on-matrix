import '../../base/test_base.dart';
import '../../scenarios/create_group_chat_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'create a new group chat',
    scenarioBuilder: ($, robots) => CreateGroupChatScenario($, robots),
  );
}
