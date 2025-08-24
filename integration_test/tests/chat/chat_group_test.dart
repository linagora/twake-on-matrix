import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../base/core_robot.dart';
import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../scenarios/chat_scenario.dart';
import '../../robots/home_robot.dart';
import 'package:patrol/patrol.dart';

// --- Common config ---
const defaultTime = Duration(seconds: 60);
const searchPhrase =
    String.fromEnvironment('SearchByTitle', defaultValue: 'My Default Group');
const forwardReceiver =
    String.fromEnvironment('Receiver', defaultValue: 'Receiver Group');

int uniqueId() => DateTime.now().microsecondsSinceEpoch;

Future<(String, String)> prepareTwoMessages(PatrolIntegrationTester $) async {
  final id = uniqueId();
  final senderMsg = 'sender sent at $id';
  final receiverMsg = 'receiver sent at $id';

  await HomeRobot($).gotoChatListScreen();
  await ChatScenario($).openChatGroupByTitle(searchPhrase);

  await ChatScenario($)
      .sendAMesage(senderMsg); // NOTE: keep current helper name
  final senderFinder = await ChatGroupDetailRobot($).getText(senderMsg);
  await $.waitUntilVisible(senderFinder, timeout: defaultTime);

  await ChatScenario($).sendAMessageByAPI(receiverMsg);
  final receiverFinder = await ChatGroupDetailRobot($).getText(receiverMsg);
  await $.waitUntilVisible(receiverFinder, timeout: defaultTime);

  return (senderMsg, receiverMsg);
}

void main() {
//   TestBase().runPatrolTest(
//     description: 'verify the display of pull down menu',
//     test: ($) async {
//       final (senderMsg, receiverMsg) = await prepareTwoMessages($);

//       await ChatGroupDetailRobot($).openPullDownMenu(senderMsg);
//       await ChatScenario($).verifyTheDisplayOfPullDownMenu(senderMsg);
//       await ChatGroupDetailRobot($).closePullDownMenu();

//       await ChatGroupDetailRobot($).openPullDownMenu(receiverMsg);
//       await ChatScenario($).verifyTheDisplayOfPullDownMenu(receiverMsg);
//     },
//   );

//   TestBase().runPatrolTest(
//     description: 'reply a message',
//     test: ($) async {
//       final (senderMsg, receiverMsg) = await prepareTwoMessages($);

//       final replySender = 'reply sender at ${uniqueId()}';
//       final replyReceiver = 'reply receiver at ${uniqueId()}';

//       await ChatScenario($).replyMessage(senderMsg, replySender);
//       await ChatScenario($).verifyMessageIsShown(replySender, true);

//       await ChatScenario($).replyMessage(receiverMsg, replyReceiver);
//       await ChatScenario($).verifyMessageIsShown(replyReceiver, true);
//     },
//   );

//   TestBase().runPatrolTest(
//     description: 'delete a message',
//     test: ($) async {
//       final (senderMsg, receiverMsg) = await prepareTwoMessages($);

//       await ChatScenario($).deleteMessage(senderMsg);
//       await ChatScenario($).verifyMessageIsShown(senderMsg, false);

//       await ChatScenario($).deleteMessage(receiverMsg);
//       await ChatScenario($).verifyMessageIsShown(receiverMsg, false);
//     },
//   );

//   TestBase().runPatrolTest(
//     description: 'copy a message',
//     test: ($) async {
//       final (senderMsg, receiverMsg) = await prepareTwoMessages($);

//       // copy sender
//       await ChatScenario($).copyMessage(senderMsg);
//       const addedText = 'Copy';
//       await ChatGroupDetailRobot($).inputMessage(addedText);
//       await ChatScenario($).pasteFromClipBoard();
//       await $(ChatInputRowSendBtn).tap();
//       await ChatScenario($).verifyMessageIsShown('$addedText$senderMsg', true);

//       // copy receiver
//       await ChatScenario($).copyMessage(receiverMsg);
//       await ChatGroupDetailRobot($).inputMessage(addedText);
//       await ChatScenario($).pasteFromClipBoard();
//       await $(ChatInputRowSendBtn).tap();
//       await ChatScenario($).verifyMessageIsShown('$addedText$receiverMsg', true);
//     },
//   );

//   TestBase().runPatrolTest(
//     description: 'edit a message',
//     test: ($) async {
//       final (senderMsg, receiverMsg) = await prepareTwoMessages($);

//       final editedSender = 'Edit$senderMsg';
//       await ChatScenario($).editMessage(senderMsg, editedSender);
//       await ChatScenario($).verifyMessageIsShown(editedSender, true);
//       await ChatScenario($).verifyMessageIsShown(senderMsg, false);

//       final editedReceiver = 'Edit$receiverMsg';
//       await ChatScenario($).editMessage(receiverMsg, editedReceiver);
//       await ChatScenario($).verifyMessageIsShown(editedReceiver, true);
//       await ChatScenario($).verifyMessageIsShown(receiverMsg, false);
//     },
//   );

//   TestBase().runPatrolTest(
//     description: 'select a message',
//     test: ($) async {
//       final (senderMsg, receiverMsg) = await prepareTwoMessages($);

//       await ChatScenario($).selectMessage(senderMsg);
//       await ChatScenario($).verifyTheDisplayInSelectedTextMode(senderMsg, 1);

//       await ChatScenario($).selectMessage(receiverMsg);
//       await ChatScenario($).verifyTheDisplayInSelectedTextMode(receiverMsg, 2);
//     },
//   );

//   // TestBase().runPatrolTest(
//   //   description: 'pin and unpin a message',
//   //   test: ($) async {
//   //     final (senderMsg, receiverMsg) = await prepareTwoMessages($);

//   //     await ChatScenario($).pinMessage(senderMsg);
//   //     await ChatScenario($).verifyMessageIsPinned(senderMsg);
//   //     await ChatScenario($).unpinMessage(senderMsg);
//   //     await ChatScenario($).verifyMessageIsPinned(senderMsg, expected: false);

//   //     await ChatScenario($).pinMessage(receiverMsg);
//   //     await ChatScenario($).verifyMessageIsPinned(receiverMsg);
//   //     await ChatScenario($).unpinMessage(receiverMsg);
//   //     await ChatScenario($).verifyMessageIsPinned(receiverMsg, expected: false);
//   //   },
//   // );

//   // TestBase().runPatrolTest(
//   //   description: 'forward a message',
//   //   test: ($) async {
//   //     final (senderMsg, receiverMsg) = await prepareTwoMessages($);

//   //     await ChatScenario($).forwardMessage(senderMsg, forwardReceiver);
//   //   },
//   // );

  TestBase().runPatrolTest(
    description: 'create a new direct message with existing account',
    test: ($) async {
      final s = SoftAssertHelper();
      const user = String.fromEnvironment('User2MaxtrixAddress');
      final now = DateTime.now();
      final message ="sender sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";

      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // click on Pen icon
      await ChatScenario($).createANewDirectMessage(user);
      // verify chat screen is shown
      s.softAssertEquals($(ChatView).exists, true, "Text: No message here yet... is not shown");
      s.softAssertEquals(ChatGroupDetailRobot($).getBackIcon().exists, true, "Back icon is not shown");
      s.softAssertEquals(ChatGroupDetailRobot($).getSearchIcon().exists, true, "Seach icon is not shown");
      s.softAssertEquals(ChatGroupDetailRobot($).getMoreIconInAppBar().exists, false, "More icon is shown");
      s.softAssertEquals($(DraftChatEmpty).exists, false, "DraftChatEmpty view is shown");

      // try to send message
      await ChatScenario($).sendAMesage(message);
      // see that message is send correctly
      await ChatScenario($).verifyMessageIsShown(message, true);
      s.verifyAll();
    },
  );

  TestBase().runPatrolTest(
    description: 'Create a new direct message with a user who hasn’t been chatted with before',
    test: ($) async {
      final s = SoftAssertHelper();
      final now = DateTime.now();
      final message ="${now.month}${now.day}${now.hour}${now.minute}";
      final nonExisingAccount ="@$message:stg.lin-saas.com";

      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // click on Pen icon
      await ChatScenario($).createANewDirectMessage(nonExisingAccount);
      // verify chat screen is shown
      s.softAssertEquals($(DraftChatEmpty).$("No message here yet...").exists, true, "No message here yet... is not shown");
      s.softAssertEquals($(DraftChatEmpty).$("Send a message or tap on the greeting below.").exists, true, "Send a message or tap on the greeting below is not shown");
      s.softAssertEquals($(DraftChatEmpty).$("🤗").exists, true, "🤗... is not shown");
      //try to send a message
      await ChatScenario($).sendAMesage(message);
      // verify the message is sent
      await ChatScenario($).verifyMessageIsShown(message, true);
      s.verifyAll();
    },
  );

  TestBase().runPatrolTest(
    description: 'create a new direct message with the non-existing account',
    test: ($) async {
      final s = SoftAssertHelper();
      final now = DateTime.now();
      final message ="${now.year}${now.month}${now.day}${now.hour}${now.minute}";
      final nonExisingAccount ="@a$message:stg.lin";

      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // click on Pen icon
      await ChatScenario($).createANewDirectMessage(nonExisingAccount);
      // verify chat screen is shown
      s.softAssertEquals($(DraftChatEmpty).$("No message here yet...").exists, true, "No message here yet... is not shown");
      s.softAssertEquals($(DraftChatEmpty).$("Send a message or tap on the greeting below.").exists, true, "Send a message or tap on the greeting below is not shown");
      s.softAssertEquals($(DraftChatEmpty).$("🤗").exists, true, "🤗... is not shown");

      //try to send a message
      await ChatScenario($).sendAMesage(message);
      
      // verify "Room creation failed" message is shown
      const failText = "Room creation failed";
      s.softAssertEquals($(failText).exists, true, "$failText is not shown");

      // verify the message is not sent
      await ChatScenario($).verifyMessageIsShown(message, false);
    },
  );
}
