import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../base/core_robot.dart';
import '../base/test_base.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/contact_list_robot.dart';
import '../robots/home_robot.dart';
import '../robots/search_robot.dart';
import '../scenarios/contact_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'working with contact screen tab',
    test: ($) async {
      final s = SoftAssertHelper();
      
      // login by UI
      await TestBase().loginAndRun($, (_) async {});
      // goto contact screen
      await HomeRobot($).gotoContactListScreen();
      await ContactScenario($).verifyDisplayOfContactListScreen(s);

      // scroll vuot contact
      await CoreRobot($).scrollToBottom($, root: $(CustomScrollView));
      await CoreRobot($).scrollToTop($,root: $(CustomScrollView),);

      //enter a non-existed contact
      await ContactScenario($).enterSearchText("noexist");
      // show no result
      s.softAssertEquals((await SearchRobot($).getNoResultIcon()).visible, true, 'lable "No Results" is not shown');

      await SearchRobot($).deleteSearchPhrase();
      //enter searchky that return a list of results
      await ContactScenario($).enterSearchText("th");
      //return a list of result
      // ignore: prefer_is_empty
      s.softAssertEquals(((await ContactListRobot($).getListOfContact()).length) >= 1, true, 'Expected at least 1 contact, but found 0');

      await SearchRobot($).deleteSearchPhrase();
      // search by address matrix
      await ContactScenario($).enterSearchText("@thhoang:linagora.com");
      // ignore: prefer_is_empty
      s.softAssertEquals(((await ContactListRobot($).getListOfContact()).length) == 1, true, 'Expected at least 1 contact, but found 0');


      await SearchRobot($).deleteSearchPhrase();
      // check case-sensitive
      await ContactScenario($).enterSearchText("@thHoang:linagora.com");
      // ignore: prefer_is_empty
      s.softAssertEquals(((await ContactListRobot($).getListOfContact()).length) == 1, true, 'Expected at least 1 contact, but found 0');
      s.softAssertEquals((await (await ContactListRobot($).getListOfContact())[0].getOwnerLabel()).visible, false, 'Owner is missing!');
      s.softAssertEquals((await (await ContactListRobot($).getListOfContact())[0].getEmailLabel()).visible, true, 'Email field is not shown');


      await SearchRobot($).deleteSearchPhrase();
      // search by current account
      await ContactScenario($).enterSearchText("@thhoang:stg.lin-saas.com");
      //verify items displayed on the TwakeListItem
      s.softAssertEquals((await ContactListRobot($).getListOfContact()).length == 1, true, '>1');
      s.softAssertEquals((await (await ContactListRobot($).getListOfContact())[0].getOwnerLabel()).visible, true, 'Owner is missing!');
      s.softAssertEquals((await (await ContactListRobot($).getListOfContact())[0].getEmailLabel()).visible, true, 'Email field is not shown');

      await SearchRobot($).deleteSearchPhrase();
      final chatGroupDetailRobot = await ContactScenario($).openChatWithContact("Thu Huyen");
      expect(await chatGroupDetailRobot.isVisible(),isTrue);

      //click back icon
      await chatGroupDetailRobot.backToPreviousScreen();
      //verify contact list screen is shown
      await ContactScenario($).verifyDisplayOfContactListScreen(s);
      s.verifyAll();
    },
  );
}