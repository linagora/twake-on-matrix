import 'package:flutter_test/flutter_test.dart';
import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/contact_list_robot.dart';
import '../../robots/home_robot.dart';
import '../../robots/search_robot.dart';
import '../../scenarios/contact_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'searching a contact',
    test: ($) async {
      final s = SoftAssertHelper();
      const searchByMatrixAddress  = String.fromEnvironment('SearchByMatrixAddress');
      const searchByTitle  = String.fromEnvironment('SearchByTitle');
      const currentAccount  = String.fromEnvironment('CurrentAccount');

      // goto contact screen
      await HomeRobot($).gotoContactListScreen();
      // verify we can scroll the screen to find a contact
      await ContactScenario($).verifyContactListCanBeScrollable(s);

      //enter a non-existed contact for searching
      await ContactScenario($).enterSearchText("noexist");
      //verify there is no result
      s.softAssertEquals((await SearchRobot($).getNoResultIcon()).visible, true, 'lable "No Results" is not shown');

      //searching by a text that included in some contacts
      await ContactScenario($).enterSearchText(currentAccount.substring(1,3));
      //verify there is more than test result
      // ignore: prefer_is_empty
      s.softAssertEquals(((await ContactListRobot($).getListOfContact()).length) >= 1, true, 'Search by $currentAccount.substring(1,3) Expected at least 1 contact, but found 0');

      // search by full an address matrix
      await ContactScenario($).enterSearchText(searchByMatrixAddress);
      //verify there is one result
      // ignore: prefer_is_empty
      s.softAssertEquals(((await ContactListRobot($).getListOfContact()).length) == 1, true, 'Search by $searchByMatrixAddress Expected at least 1 contact, but found 0');

      // search by full an address matrix but make it in case-sensitive format
      await ContactScenario($).enterSearchText(searchByMatrixAddress.toUpperCase());
      //verify there is one result
      // ignore: prefer_is_empty
      s.softAssertEquals(((await ContactListRobot($).getListOfContact()).length) == 1, true, 'Search by $searchByMatrixAddress.toUpperCase() Expected at least 1 contact, but found 0');
      s.softAssertEquals((await (await ContactListRobot($).getListOfContact())[0].getOwnerLabel()).visible, false, 'Owner is missing!');
      s.softAssertEquals((await (await ContactListRobot($).getListOfContact())[0].getEmailLabel()).visible, true, 'Email field is not shown');

      // search by current account
      await ContactScenario($).enterSearchText(currentAccount);
      //verify componen displayed on the TwakeListItem
      s.softAssertEquals((await ContactListRobot($).getListOfContact()).length == 1, true, '>1');
      s.softAssertEquals((await (await ContactListRobot($).getListOfContact())[0].getOwnerLabel()).visible, true, 'Owner is missing!');
      s.softAssertEquals((await (await ContactListRobot($).getListOfContact())[0].getEmailLabel()).visible, true, 'Email field is not shown');

      // after searching, open a chat by clicking on a result
      final chatGroupDetailRobot = await ContactScenario($).openChatWithContact(searchByTitle);
      //verify group chat detail screen is shown
      expect(await chatGroupDetailRobot.isVisible(),isTrue);

      //back to contact list
      await ContactScenario($).backToContactLisFromChatGroupScreen();
      //verify contact list screen is shown gain with correct display
      await ContactScenario($).verifyDisplayOfContactListScreen(s);
      s.verifyAll();
    },
  );
}