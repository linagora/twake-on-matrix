import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_events_view.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../scenarios/chat_scenario.dart';
import '../../robots/home_robot.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'do actions on a message',
    test: ($) async {
      final s = SoftAssertHelper();

      const searchPharse = 'Thu Huyen HOANG';
      // const groupID = "!jmWMCwSFwoXpofpmqQ";
      const messageOfSender = "sender sent at 2025728100";
      const messageOfReceiver = "receiver sent at 20257271640";
      final now = DateTime.now();
      // final messageOfSender = "sender sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
      // final messageOfReceiver = "receiver sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
        
      await TestBase().loginAndRun($, (_) async {});
      //to close popup
      await HomeRobot($).gotoContactListScreen();
      // goto contact screen
      await HomeRobot($).gotoChatListScreen();
      // search to Open chat group
      await ChatScenario($).openChatGroupByTitle(searchPharse);
      // await ChatScenario($).verifyTheDisplayOfPullDownMenu(messageOfSender);
      // await ChatScenario($).verifyTheDisplayOfPullDownMenu(messageOfReceiver);

      // final replySender = "reply sender at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
      // final replyReceiver = "reply receiver at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
      // //reply message of sender
      // await ChatScenario($).replyMessage(messageOfSender, replySender);
      // //verify the message is replied
      // await ChatScenario($).verifyMessageIsShown(replySender, true);
      // //reply message of receiver
      // await ChatScenario($).replyMessage(messageOfReceiver, replyReceiver);
      // //verify the message is replied
      // await ChatScenario($).verifyMessageIsShown(replyReceiver, true);

      // //delete a sender message
      // await ChatScenario($).deleteMessage(replySender);
      // //verify the message is deleted
      // await ChatScenario($).verifyMessageIsShown(replySender, false);
      // //delete a sender receiver
      // await ChatScenario($).deleteMessage(replyReceiver);
      // //verify the message is deleted
      // await ChatScenario($).verifyMessageIsShown(replyReceiver, false);

      // //copy message of sender
      // await ChatScenario($).copyMessage(messageOfSender);
      // //paste into TextField
      // const addedText = "Copy";
      // await ChatGroupDetailRobot($).inputMessage(addedText);
      // await ChatScenario($).pasteFromClipBoard();
      // await $(ChatInputRowSendBtn).tap();
      // // verify the message is copied
      // await ChatScenario($).verifyMessageIsShown("$addedText$messageOfSender", true);
      // await ChatScenario($).deleteMessage("$addedText$messageOfSender");

      // // copy message of receiver
      // await ChatScenario($).copyMessage(messageOfReceiver);
      // //paste into TextField
      // await ChatGroupDetailRobot($).inputMessage(addedText);
      // await ChatScenario($).pasteFromClipBoard();
      // await $(ChatInputRowSendBtn).tap();
      // // verify the message is copied
      // await ChatScenario($).verifyMessageIsShown("$addedText$messageOfReceiver", true);
      // await ChatScenario($).deleteMessage("$addedText$messageOfReceiver");

      // //select message of sender
      // await ChatScenario($).selectMessage(messageOfSender);
      // //verify the message is selected
      // await ChatScenario($).verifyTheDisplayInSelectedTextMode(messageOfSender);
      // //select message of receiver
      // await ChatScenario($).selectMessage(messageOfReceiver);
      // //verify the message is selected
      // await ChatScenario($).verifyTheDisplayInSelectedTextMode(messageOfReceiver);

      // //pin a sender message
      // await ChatScenario($).pinMessage(messageOfSender);
      // //verify pin is pinned()
      // await ChatScenario($).verifyMessageIsPinned(messageOfSender, true);
      // //pin a receiver message
      // await ChatScenario($).pinMessage(messageOfReceiver);
      // //verify pin is pinned()
      // await ChatScenario($).verifyMessageIsPinned(messageOfReceiver, true);

      // //edit message of sender
      // await ChatScenario($).editMessage(messageOfSender, "Edit$messageOfSender");
      // //verify the message is edited
      // await ChatScenario($).verifyMessageIsShown("Edit$messageOfSender", true);
      // await ChatScenario($).verifyMessageIsShown(messageOfSender, false);
      // await ChatScenario($).deleteMessage("Edit$messageOfSender");
      // //edit message of receiver
      // await ChatScenario($).editMessage(messageOfReceiver,  "Edit$messageOfReceiver");
      // //verify the message is edited
      // await ChatScenario($).verifyMessageIsShown("Edit$messageOfReceiver", true);
      // await ChatScenario($).verifyMessageIsShown(messageOfReceiver, false);
      // await ChatScenario($).deleteMessage("Edit$messageOfReceiver");

      //forward message of sender
      const receiver = "thhoang2";
      await ChatScenario($).forwardMessage(messageOfSender, receiver);
      // //verify the message is forwarded
      // s.softAssertEquals(ChatGroupDetailRobot($).getTitle()?.contains(receiver), true,"title not contains $receiver");
      // await ChatScenario($).verifyMessageIsShown(messageOfSender, true);

      s.verifyAll();
    },
  );
}

