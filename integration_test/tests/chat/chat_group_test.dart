import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/event_info_dialog.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../base/base_scenario.dart';
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
  TestBase().runPatrolTest(
    description: 'verify the display of pull down menu in a direct chat',
    test: ($) async {
      final (senderMsg, receiverMsg) = await prepareTwoMessages($);

      await ChatGroupDetailRobot($).openPullDownMenuOfAMessage(senderMsg);
      await ChatScenario($).verifyTheDisplayOfPullDownMenu(
        senderMsg,
        level: UserLevel.owner,
        isMsgOfLogginUser: true,
      );
      await ChatGroupDetailRobot($).closePullDownMenu();

      await ChatGroupDetailRobot($).openPullDownMenuOfAMessage(receiverMsg);
      await ChatScenario($)
          .verifyTheDisplayOfPullDownMenu(receiverMsg, level: UserLevel.member);
    },
  );

  TestBase().runPatrolTest(
    description: 'reply a message in a direct chat',
    test: ($) async {
      final (senderMsg, receiverMsg) = await prepareTwoMessages($);

      final replySender = 'reply sender at ${uniqueId()}';
      final replyReceiver = 'reply receiver at ${uniqueId()}';

      await ChatScenario($).replyMessage(senderMsg, replySender);
      await ChatScenario($).verifyMessageIsShown(replySender, true);

      await ChatScenario($).replyMessage(receiverMsg, replyReceiver);
      await ChatScenario($).verifyMessageIsShown(replyReceiver, true);
    },
  );

  TestBase().runPatrolTest(
    description: 'delete a message in a direct chat',
    test: ($) async {
      final (senderMsg, receiverMsg) = await prepareTwoMessages($);
      await ChatScenario($).deleteMessage(senderMsg);
      await ChatScenario($).verifyMessageIsShown(senderMsg, false);
    },
  );

  TestBase().runPatrolTest(
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
      await ChatScenario($)
          .verifyMessageIsShown('$addedText$receiverMsg', true);
    },
  );

  TestBase().runPatrolTest(
    description: 'edit a message with owner level',
    test: ($) async {
      final (senderMsg, receiverMsg) = await prepareTwoMessages($);

      final editedSender = 'Edit$senderMsg';
      await ChatScenario($).editMessage(senderMsg, editedSender);
      await ChatScenario($).verifyMessageIsShown(editedSender, true);
      await ChatScenario($).verifyMessageIsShown(senderMsg, false);
    },
  );

  TestBase().runPatrolTest(
    description: 'select a message in direct chat',
    test: ($) async {
      final (senderMsg, receiverMsg) = await prepareTwoMessages($);

      await ChatScenario($).selectMessage(senderMsg);
      await ChatScenario($).verifyTheDisplayInSelectedTextMode(senderMsg, 1);

      await ChatScenario($).selectMessage(receiverMsg);
      await ChatScenario($).verifyTheDisplayInSelectedTextMode(receiverMsg, 2);
    },
  );

  // TestBase().runPatrolTest(
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
  //   description: 'forward a message',
  //   test: ($) async {
  //     final (senderMsg, receiverMsg) = await prepareTwoMessages($);

  //     await ChatScenario($).forwardMessage(senderMsg, forwardReceiver);
  //   },
  // );

  TestBase().runPatrolTest(
    description: 'See message info',
    test: ($) async {
      final (senderMsg, receiverMsg) = await prepareTwoMessages($);
      final s = SoftAssertHelper();
      await ChatScenario($).watchMessageInfo(senderMsg);
      // verify info dialog is shown
      s.softAssertEquals(
        $(EventInfoDialog).exists,
        true,
        'EventInfoDialog is not shown',
      );
      //Verify contains avatar
      s.softAssertEquals(
        $(EventInfoDialog).$(ListTile).at(0).$(Avatar).exists,
        true,
        'Avatar is not shown',
      );
      //Verify contains the time message is sent
      s.softAssertEquals(
        $(EventInfoDialog).$(ListTile).at(1).$(Text).at(1).text != "",
        true,
        'sent time is not shown',
      );
      // verify type is text
      s.softAssertEquals(
        $(EventInfoDialog).$(ListTile).at(2).$(Text).at(1).text == "text",
        true,
        'type is not text',
      );
      // verify source code is shown
      s.softAssertEquals(
        $(EventInfoDialog).$(SelectableText).exists,
        true,
        'source code is not shown',
      );
      //close message info
      await ChatScenario($).closeMessageInfo();

      s.verifyAll();
    },
  );
}
