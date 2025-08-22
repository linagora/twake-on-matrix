import 'package:flutter_test/flutter_test.dart';
import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/chat_list_robot.dart';
import '../../scenarios/chat_scenario.dart';
import '../../robots/home_robot.dart';
import '../../robots/search_robot.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'searching a chat group',
    test: ($) async {
      final s = SoftAssertHelper();
      const searchByMatrixAddress  = String.fromEnvironment('SearchByMatrixAddress');
      const searchByTitle  = String.fromEnvironment('SearchByTitle');
      const currentAccount  = String.fromEnvironment('CurrentAccount');

      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // verify we can scroll the screen to find a contact
      await ChatScenario($).verifyChatListCanBeScrollable(s);

      //enter a non-existed group for searching
      await ChatScenario($).enterSearchText("noexist");
      //verify there is no result
      s.softAssertEquals((await SearchRobot($).getNoResultIcon()).visible, true,'lable "No Results" is not shown');

      //searching by a text that included in some groups
      await ChatScenario($).enterSearchText(currentAccount.substring(1,3));
      await ChatScenario($).verifySearchResultViewIsShown();
      await ChatScenario($).verifySearchResultContains(currentAccount.substring(1,3));
      //return a list of result
      // ignore: prefer_is_empty
      s.softAssertEquals(((await ChatListRobot($).getListOfChatGroup()).length) >= 1, true, 'Searchby $currentAccount.substring(1,3) Expected at least 1 group, but found 0',);

      // search by full an address matrix
      await ChatScenario($).enterSearchText(searchByMatrixAddress);
      //verify there is one result
      // ignore: prefer_is_empty
      s.softAssertEquals((await ChatListRobot($).getListOfChatGroup()).length == 1, true, 'Search by $searchByMatrixAddress Expected at least 1 group, but found 0');

      // search by full an address matrix but make it in case-sensitive format
      await ChatScenario($).enterSearchText(searchByMatrixAddress.toUpperCase());
      //verify there is one result
      // ignore: prefer_is_empty
      s.softAssertEquals((await ChatListRobot($).getListOfChatGroup()).length == 1, true, 'Searhc by $searchByMatrixAddress.toUpperCase() Expected at least 1 group, but found 0');

      // search by current account
      await ChatScenario($).enterSearchText(currentAccount);
      //verify items displayed on the TwakeListItem
      s.softAssertEquals((await ChatListRobot($).getListOfChatGroup()).length == 1, true, '>1',);
      s.softAssertEquals((await (await ChatListRobot($).getListOfChatGroup())[0].getOwnerLabel()).visible, true, 'Owner is missing!',);
      s.softAssertEquals((await (await ChatListRobot($).getListOfChatGroup())[0].getEmailLabel()).visible, true, 'Email field is not shown',);

      // after searching, open a chat by clicking on a result
      final chatGroupDetailRobot = await ChatScenario($).openChatGroup(searchByTitle);
      //verify group chat detail screen is shown
      expect(await chatGroupDetailRobot.isVisible(), isTrue);

      //back to chat list
      await ChatScenario($).backToChatLisFromChatGroupScreen(true);
      //verify chat list screen is shown gain with correct display
      await ChatScenario($).verifyDisplayOfGroupListScreen(s);

      s.verifyAll();
    },
  );
}
