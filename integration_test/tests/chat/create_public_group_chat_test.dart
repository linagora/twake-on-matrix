import '../../base/test_base.dart';
import '../../scenarios/create_public_group_chat_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'create a public group chat limited to the homeserver',
    scenarioBuilder: ($, robots) => CreatePublicGroupChatScenario($, robots),
  );
}
