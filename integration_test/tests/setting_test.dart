import '../base/test_base.dart';
import '../robots/chat_list_robot.dart';
import '../scenarios/chat_scenario.dart';
import '../scenarios/message_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Checking sending message between members',
    test: ($) async {
      const searchPharse = 'Thu Huyen HOANG';
      const groupID = "!jmWMCwSFwoXpofpmqQ";
      // login by UI

      await TestBase().loginAndRun($, (_) async {
         // search to Open chat group
        await ChatListRobot($).enterSearchText(searchPharse);
        await ChatListRobot($).openChatGroupByIndex(0);
        // send a message
        final now = DateTime.now();
        final messageOfSender = "sender sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
        final messageOfReceiver = "receiver sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
        await ChatScenario($).sendAMesage(messageOfSender);

        // check message is sent
        await ChatScenario($).verifyMessageIsShown(messageOfSender);
        //// receiver read message
        //
        //// check sender see message is read
        //...
        // send message by API
        await Future.delayed(const Duration(seconds: 10)); 
        await ChatScenario($).sendAMessageByAPI(groupID, messageOfReceiver);
        // check message is shown on UI
        await Future.delayed(const Duration(seconds: 30)); 
        await ChatScenario($).verifyMessageIsShown(messageOfReceiver);
      });
    },
  );
}