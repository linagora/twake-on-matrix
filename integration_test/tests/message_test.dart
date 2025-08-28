import '../base/test_base.dart';
import '../robots/chat_list_robot.dart';
import '../scenarios/message_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Checking sending message between members',
    test: ($) async {
      const searchPharse = 'Thu Huyen HOANG';
      const groupID = "!jmWMCwSFwoXpofpmqQ";
      // login by UI

      await TestBase().loginAndRun($, (_) async {
        // in chat screen, we make a search by group title
        await ChatListRobot($).enterSearchText(searchPharse);
        // open the group
        await ChatListRobot($).openChatGroupByIndex(0);
        // user send a message
        final now = DateTime.now();
        final messageOfSender = "sender sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
        final messageOfReceiver = "receiver sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
        await MessageScenario($).sendAMesage(messageOfSender);

        // verify message is sent
        await MessageScenario($).verifyMessageIsShown(messageOfSender);
        // simulate other member in group send a message
        await Future.delayed(const Duration(seconds: 10)); 
        await MessageScenario($).sendAMessageByAPI(groupID, messageOfReceiver);
        // verify the message sent by other member is displayed on screen
        await Future.delayed(const Duration(seconds: 30)); 
        await MessageScenario($).verifyMessageIsShown(messageOfReceiver);
      });
    },
  );
}