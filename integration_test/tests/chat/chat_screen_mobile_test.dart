import '../../base/test_base.dart';
import '../../scenarios/chat_screen_scenarios.dart';

void main() {
  TestBase().runPatrolTest(
    tags: ['chat_screen_mobile_test01'],
    description: 'Swipe a message to reply to it',
    scenarioBuilder: ($, robots) => SwipeToReplyScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['chat_screen_mobile_test02'],
    description: 'Typing @ suggests every other member of the room',
    scenarioBuilder: ($, robots) => MentionSuggestionsScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['chat_screen_mobile_test03'],
    description: 'Searching in a chat lists every related message',
    scenarioBuilder: ($, robots) => SearchAllRelatedMessagesScenario($, robots),
  );
}
