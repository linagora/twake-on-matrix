import '../../base/test_base.dart';
import '../../scenarios/chat_group_scenario.dart';

void main() {
  // Mobile-only: the pull-down menu layout assertion is specific to the mobile
  // long-press menu (web uses a hover action bar).
  TestBase().runPatrolTest(
    tags: ["chat_group_test_test01"],
    description: 'verify the display of pull down menu in a direct chat',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ChatGroupDisplayMenuScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ["chat_group_test_test02"],
    description: 'reply a message in a group chat',
    scenarioBuilder: ($, robots) => ChatGroupReplyScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ["chat_group_test_test03"],
    description: 'delete a message in a group chat',
    scenarioBuilder: ($, robots) => ChatGroupDeleteScenario($, robots),
  );

  // Mobile-only: copy goes through `Clipboard.setData`, which headless-web
  // Chrome blocks without a user gesture (`PlatformException(copy_fail)`).
  TestBase().runPatrolTest(
    tags: ["chat_group_test_test04"],
    description: 'copy a message in a direct chat',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ChatGroupCopyScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ["chat_group_test_test05"],
    description: 'edit a message with owner level',
    scenarioBuilder: ($, robots) => ChatGroupEditScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ["chat_group_test_test06"],
    description: 'select a message in a group chat',
    scenarioBuilder: ($, robots) => ChatGroupSelectScenario($, robots),
  );

  // test07 (pin / unpin) and test08 (forward) are not yet migrated.

  TestBase().runPatrolTest(
    tags: ["chat_group_test_test09"],
    description: 'See message info',
    scenarioBuilder: ($, robots) => ChatGroupMessageInfoScenario($, robots),
  );
}
