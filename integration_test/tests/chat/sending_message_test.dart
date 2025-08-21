import '../../base/test_base.dart';
import '../../robots/chat_list_robot.dart';
import '../../robots/home_robot.dart';
import '../../scenarios/chat_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Checking sending message between members',
    test: ($) async {
      const searchPharse = 'Thu Huyen HOANG';
      await HomeRobot($).gotoChatListScreen();
      await ChatScenario($).enterSearchText(searchPharse);
      await ChatListRobot($).openChatGroupByIndex(0);
      // send a message
      final now = DateTime.now();
      final messageOfSender =
          "sender sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
      final messageOfReceiver =
          "receiver sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";
      await ChatScenario($).sendAMesage(messageOfSender);

      // check message is sent
      await ChatScenario($).verifyMessageIsShown(messageOfSender, true);

      // send message by API
      await ChatScenario($).sendAMessageByAPI(messageOfReceiver);
      // check message is shown on UI
      await ChatScenario($).verifyMessageIsShown(messageOfReceiver, true);
    },
  );
}
