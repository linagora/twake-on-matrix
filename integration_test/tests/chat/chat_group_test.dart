import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../base/test_base.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../scenarios/chat_group_scenario.dart';
import '../../scenarios/chat_scenario.dart';
import '../../robots/home_robot.dart';
import 'package:patrol/patrol.dart';

// --- Common config ---
const defaultTime = Duration(seconds: 60);
const searchPhrase = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'My Default Group',
);
const forwardReceiver = String.fromEnvironment(
  'Receiver',
  defaultValue: 'Receiver Group',
);

int uniqueId() => DateTime.now().microsecondsSinceEpoch;

Future<(String, String)> prepareTwoMessages(PatrolIntegrationTester $) async {
  final id = uniqueId();
  final senderMsg = 'sender sent at $id';
  final receiverMsg = 'receiver sent at $id';

  await HomeRobot($).gotoChatListScreen();
  await ChatScenario($).openChatGroupByTitle(searchPhrase);

  await ChatScenario(
    $,
  ).sendAMesage(senderMsg); // NOTE: keep current helper name
  final senderFinder = await ChatGroupDetailRobot($).getText(senderMsg);
  await $.waitUntilVisible(senderFinder, timeout: defaultTime);

  await ChatScenario($).sendAMessageByAPI(receiverMsg);
  final receiverFinder = await ChatGroupDetailRobot($).getText(receiverMsg);
  await $.waitUntilVisible(receiverFinder, timeout: defaultTime);

  return (senderMsg, receiverMsg);
}

void main() {
  TestBase().runPatrolTest(
    tags: ["chat_group_test_test01"],
    description: 'verify the display of pull down menu in a direct chat',
    test: ($) async {
      final (senderMsg, receiverMsg) = await prepareTwoMessages($);

      await ChatGroupDetailRobot($).openPullDownMenu(senderMsg);
      await ChatScenario(
        $,
      ).verifyTheDisplayOfPullDownMenu(senderMsg, level: UserLevel.owner);
      await ChatGroupDetailRobot($).closePullDownMenu();

      await ChatGroupDetailRobot($).openPullDownMenu(receiverMsg);
      await ChatScenario(
        $,
      ).verifyTheDisplayOfPullDownMenu(receiverMsg, level: UserLevel.member);
    },
  );

  // Migrated to the cross-platform `scenarioBuilder` API (PR 9b-2a).
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

  // Stays mobile-only (legacy `test:`, skipped on web). Copy goes through
  // `Clipboard.setData`, which the headless-web browser blocks without a user
  // gesture / clipboard permission — patrol's Chrome throws
  // `PlatformException(copy_fail, Clipboard.setData failed.)`. This is a real
  // browser limitation, not a harness gap, so the copy flow cannot be made
  // web-green; it remains validated on mobile.
  TestBase().runPatrolTest(
    tags: ["chat_group_test_test04"],
    description: 'copy a message in a direct chat',
    test: ($) async {
      final (senderMsg, receiverMsg) = await prepareTwoMessages($);

      // copy sender
      await ChatScenario($).copyMessage(senderMsg);
      const addedText = 'Copy';
      await ChatGroupDetailRobot($).inputMessage(addedText);
      await ChatScenario($).pasteFromClipBoard();
      await $(ChatInputRowSendBtn).tap();
      await ChatScenario($).verifyMessageIsShown('$addedText$senderMsg', true);

      // copy receiver
      await ChatScenario($).copyMessage(receiverMsg);
      await ChatGroupDetailRobot($).inputMessage(addedText);
      await ChatScenario($).pasteFromClipBoard();
      await $(ChatInputRowSendBtn).tap();
      await ChatScenario(
        $,
      ).verifyMessageIsShown('$addedText$receiverMsg', true);
    },
  );

  // Migrated to the cross-platform `scenarioBuilder` API (PR 9b-2b).
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

  // TestBase().runPatrolTest(
  //   tags: ["chat_group_test_test07"],
  //   description: 'pin and unpin a message',
  //   test: ($) async {
  //     final (senderMsg, receiverMsg) = await prepareTwoMessages($);

  //     await ChatScenario($).pinMessage(senderMsg);
  //     await ChatScenario($).verifyMessageIsPinned(senderMsg);
  //     await ChatScenario($).unpinMessage(senderMsg);
  //     await ChatScenario($).verifyMessageIsPinned(senderMsg, expected: false);

  //     await ChatScenario($).pinMessage(receiverMsg);
  //     await ChatScenario($).verifyMessageIsPinned(receiverMsg);
  //     await ChatScenario($).unpinMessage(receiverMsg);
  //     await ChatScenario($).verifyMessageIsPinned(receiverMsg, expected: false);
  //   },
  // );

  // TestBase().runPatrolTest(
  //   tags: ["chat_group_test_test08"],
  //   description: 'forward a message',
  //   test: ($) async {
  //     final (senderMsg, receiverMsg) = await prepareTwoMessages($);

  //     await ChatScenario($).forwardMessage(senderMsg, forwardReceiver);
  //   },
  // );

  // Migrated to the cross-platform `scenarioBuilder` API (PR 9b-2c).
  TestBase().runPatrolTest(
    tags: ["chat_group_test_test09"],
    description: 'See message info',
    scenarioBuilder: ($, robots) => ChatGroupMessageInfoScenario($, robots),
  );
}
