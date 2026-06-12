import '../../base/test_base.dart';
import '../../scenarios/create_direct_chat_with_unsupported_user_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Should not create any chat '
        'when create direct chat with unsupported matrix user',
    scenarioBuilder: ($, robots) =>
        CreateDirectChatWithUnsupportedUserScenario($, robots),
  );
}
