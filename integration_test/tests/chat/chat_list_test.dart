import '../../base/test_base.dart';
import '../../scenarios/chat_list_scenarios.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'searching a chat group',
    scenarioBuilder: ($, robots) => ChatListSearchScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Count unread messages',
    scenarioBuilder: ($, robots) => UnreadCountScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Unread badge clears after viewing at the live bottom',
    scenarioBuilder: ($, robots) => UnreadBadgeClearsScenario($, robots),
  );

  TestBase().runPatrolTest(
    description: 'Pin/unpin a chat',
    scenarioBuilder: ($, robots) => PinChatScenario($, robots),
  );
}
