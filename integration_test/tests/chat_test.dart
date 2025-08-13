import 'package:flutter_test/flutter_test.dart';
import '../base/test_base.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/chat_list_robot.dart';
import '../scenarios/chat_scenario.dart';
import 'package:flutter/material.dart';
import '../base/core_robot.dart';
import '../robots/home_robot.dart';
import '../robots/search_robot.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'working with chat screen tab',
    test: ($) async {
      final s = SoftAssertHelper();
      
      // login by UI
      await TestBase().loginAndRun($, (_) async {});
      //to close popup
      await HomeRobot($).gotoContactListScreen();
      // goto contact screen
      await HomeRobot($).gotoChatListScreen();
      await ChatScenario($).verifyDisplayOfContactListScreen(s);

      // scroll vuot contact
      await CoreRobot($).scrollToBottom($, root: $(SingleChildScrollView));
      await CoreRobot($).scrollToTop($,root: $(SingleChildScrollView),);

      //enter a non-existed contact
      await ChatScenario($).enterSearchText("noexist");
      // show no result
      s.softAssertEquals((await SearchRobot($).getNoResultIcon()).visible, true, 'lable "No Results" is not shown');

      await SearchRobot($).deleteSearchPhrase();
      //enter searchky that return a list of results
      await ChatScenario($).enterSearchText("th");
      await ChatScenario($).verifySearchResultViewIsShown();
      await ChatScenario($).verifySearchResultContains("th");
      //return a list of result
      // ignore: prefer_is_empty
      s.softAssertEquals(((await ChatListRobot($).getListOfChatGroup()).length) >= 1, true, 'Expected at least 1 contact, but found 0');

      await SearchRobot($).deleteSearchPhrase();
      // search by address matrix
      await ChatScenario($).enterSearchText("@thhoang:linagora.com");
      // ignore: prefer_is_empty
      s.softAssertEquals((await ChatListRobot($).getListOfChatGroup()).length == 1, true, 'Expected at least 1 contact, but found 0');


      await SearchRobot($).deleteSearchPhrase();
      // check case-sensitive
      await ChatScenario($).enterSearchText("@thHoang:linagora.com");
      // ignore: prefer_is_empty
      s.softAssertEquals((await ChatListRobot($).getListOfChatGroup()).length == 1, true, 'Expected at least 1 contact, but found 0');


      await SearchRobot($).deleteSearchPhrase();
      // search by current account
      await ChatScenario($).enterSearchText("@thhoang:stg.lin-saas.com");
      //verify items displayed on the TwakeListItem
      s.softAssertEquals((await ChatListRobot($).getListOfChatGroup()).length == 1, true, '>1');
      s.softAssertEquals((await (await ChatListRobot($).getListOfChatGroup())[0].getOwnerLabel()).visible, true, 'Owner is missing!');
      s.softAssertEquals((await (await ChatListRobot($).getListOfChatGroup())[0].getEmailLabel()).visible, true, 'Email field is not shown');

      await SearchRobot($).deleteSearchPhrase();
      final chatGroupDetailRobot = await ChatScenario($).openChatGroup("Thu Huyen HOANG");
      expect(await chatGroupDetailRobot.isVisible(),isTrue);

      //click back icon
      await chatGroupDetailRobot.backToPreviousScreen();
      await SearchRobot($).backToPreviousScreen();

      //verify contact list screen is shown
      await ChatScenario($).verifyDisplayOfContactListScreen(s);
      s.verifyAll();
    },
  );

  TestBase().runPatrolTest(
    description: 'Checking sending message between members',
    test: ($) async {
      const searchPharse = 'Thu Huyen HOANG';
      const groupID = "!jmWMCwSFwoXpofpmqQ";
      // login by UI

      await TestBase().loginAndRun($, (_) async {
         // search to Open chat group
        await ChatScenario($).enterSearchText(searchPharse);
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

