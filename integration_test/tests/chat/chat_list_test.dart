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
      s.softAssertEquals((await ChatListRobot($).getListOfChatGroup()).isNotEmpty, true, 'Searchby $currentAccount.substring(1,3) Expected at least 1 group, but found 0',);

      // search by full an address matrix
      await ChatScenario($).enterSearchText(searchByMatrixAddress);
      //verify there is one result
      s.softAssertEquals((await ChatListRobot($).getListOfChatGroup()).length == 1, true, 'Search by $searchByMatrixAddress Expected number of group is 1 , but found != 1');

      // search by full an address matrix but make it in case-sensitive format
      await ChatScenario($).enterSearchText(searchByMatrixAddress.toUpperCase());
      //verify there is one result
      s.softAssertEquals((await ChatListRobot($).getListOfChatGroup()).length == 1, true, 'Searhc by $searchByMatrixAddress.toUpperCase() Expected number of group is 1 , but found != 1');

      // search by current account
      await ChatScenario($).enterSearchText(currentAccount);
      //verify items displayed on the TwakeListItem
      //todo: handle the case list both contact and Message
      s.softAssertEquals((await (await ChatListRobot($).getListOfChatGroup())[0].getOwnerLabel()).visible, true, 'Owner is missing!',);
      s.softAssertEquals((await (await ChatListRobot($).getListOfChatGroup())[0].getEmailLabelIncaseSearching()).visible, true, 'Email field is not shown',);

      // after searching, open a chat by clicking on a result
      final chatGroupDetailRobot = await ChatScenario($).openChatGroup(searchByTitle);
      //verify group chat detail screen is shown
      expect(await chatGroupDetailRobot.isVisible(), isTrue);

      //back to chat list
      await ChatScenario($).backToChatLisFromChatGroupScreen(isOpenGroupFromSearchResult: true);
      //verify chat list screen is shown gain with correct display
      await ChatScenario($).verifyDisplayOfGroupListScreen(s);

      s.verifyAll();
    },
  );

  TestBase().runPatrolTest(
    description: 'Count unread messages',
    test: ($) async {
      final now = DateTime.now();
      const groupTest = String.fromEnvironment('TitleOfGroupTest');
      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      //send a message by API to groupTest
      await ChatScenario($).sendAMessageByAPI("${now.month}${now.day}${now.hour}${now.minute}");  
      //get current unread message of groupTest
      final numberOfUnreadMessage1 = ChatListRobot($).getUnreadMessage(groupTest) ;

      //send the ome more message by API
      await ChatScenario($).sendAMessageByAPI("${now.month}${now.day}${now.hour}${now.minute}");  
      //get current unread message of groupTest
      final numberOfUnreadMessage2 = ChatListRobot($).getUnreadMessage(groupTest) ;

      expect((numberOfUnreadMessage2 - numberOfUnreadMessage1) ==1, isTrue,
        reason: "expect the different is 1 but the second is $numberOfUnreadMessage2 and the first is $numberOfUnreadMessage1",);
    },
  );

  TestBase().runPatrolTest(
    description: 'Pin/unpin a chat',
    test: ($) async {
      const groupTest = String.fromEnvironment('GroupTest');
      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // pin a chat
      await ChatScenario($).pinAChat(groupTest);  
      // verify the chat is pin
      await ChatScenario($).verifyAChatIsPin(groupTest, true);
      
      // unpin a chat
      await ChatScenario($).unPinAChat(groupTest);  
      // verify the chat is unPin
      await ChatScenario($).verifyAChatIsPin(groupTest, false);
    },
  );

  TestBase().runPatrolTest(
    description: 'mark read/unread for a chat',
    test: ($) async {
      final now = DateTime.now();
      const groupTest = String.fromEnvironment('TitleOfGroupTest');
      final receiverMsg ="receiver sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";

      // goto chat screen
      await HomeRobot($).gotoChatListScreen();

      // make sure there is unread message by sending an new message by API
      await ChatScenario($).sendAMessageByAPI(receiverMsg);
      await $.waitUntilVisible(ChatListRobot($).getChatGroupByTitle(groupTest).getNumberUnReadIcon());
      //todo: improve hard wait here
      //Sometime, the row is change it's order. It can lead a failure when try to take an long press
      //So that, I make a wait here
      await Future.delayed(const Duration(seconds: 3));

      // mark as read for the chat
      await ChatScenario($).markAChatAsRead(groupTest);  
      // verify the chat is displayed as read
      await ChatScenario($).verifyAChatIsMarkAsUnRead(groupTest, false);
      
      // mark as unread for the chat
      await ChatScenario($).markAChatAsUnread(groupTest);  
      // verify the chat is displayed as uread
      await ChatScenario($).verifyAChatIsMarkAsUnRead(groupTest, true);
    },
  );

  TestBase().runPatrolTest(
    description: 'Mute/unmute a chat',
    test: ($) async {
      const groupTest = String.fromEnvironment('TitleOfGroupTest');
      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // mute a chat
      await ChatScenario($).muteAChat(groupTest);  
      // verify the chat is pin
      await ChatScenario($).verifyAChatIsMuted(groupTest, true);
      
      // unmute a chat
      await ChatScenario($).unmuteAChat(groupTest);  
      // verify the chat is unPin
      await ChatScenario($).verifyAChatIsMuted(groupTest, false);
    },
  );

  TestBase().runPatrolTest(
    description: 'verify the display of context menu after swipe a chat',
    test: ($) async {
      final s = SoftAssertHelper();
      const groupTest = String.fromEnvironment('TitleOfGroupTest');
      // goto chat screen
      await HomeRobot($).gotoChatListScreen();

      final row = ChatListRobot($).getChatGroupByTitle(groupTest);
      //make sure the chat is unmute
      await ChatScenario($).unmuteAChat(groupTest);
      //send a message to the group to make it has unread message
      await ChatScenario($).sendAMessageByAPI(groupTest);
      await $.waitUntilVisible(row.getNumberUnReadIcon());

      // pin unmute
      await ChatScenario($).pinAChat(groupTest);
      await ChatScenario($).unmuteAChat(groupTest);
      //swipe a chat co tin mơi
      await ChatScenario($).leftSwipe(groupTest);
      //verify the display of buttons
      s.softAssertEquals((row.getReadBtn()).visible, true, 'there is no Read in case 1');
      s.softAssertEquals((row.getMuteBtn()).visible, true, 'there is no Mute in case 1');
      s.softAssertEquals((row.getUnpinBtn()).visible, true, 'there is no Unpin in case 1');
      s.softAssertEquals((row.getUnreadBtn()).visible, false, 'there is UnRead in case 1');
      s.softAssertEquals((row.getUnmuteBtn()).visible, false, 'there is Unmute in case 1');
      s.softAssertEquals((row.getPinBtn()).visible, false, 'there is Pin in case 1');

      // pin mute
      //swipe a chat co tin mơi
      await row.mute();
      await ChatScenario($).leftSwipe(groupTest);
      //verify the display of buttons
      s.softAssertEquals((row.getReadBtn()).visible, true, 'there is no Read in case 2');
      s.softAssertEquals((row.getUnmuteBtn()).visible, true, 'there is no unmute in case 2');
      s.softAssertEquals((row.getUnpinBtn()).visible, true, 'there is no Unpin in case 2');
      s.softAssertEquals((row.getUnreadBtn()).visible, false, 'there is UnRead in case 2');
      s.softAssertEquals((row.getMuteBtn()).visible, false, 'there is mute in case 2');
      s.softAssertEquals((row.getPinBtn()).visible, false, 'there is Pin in case 2');

      // unpin mute
      //swipe a chat co tin mơi
      await row.unpin();
      await ChatScenario($).leftSwipe(groupTest);
      //verify the display of buttons
      s.softAssertEquals((row.getReadBtn()).visible, true, 'there is no Read in case 3');
      s.softAssertEquals((row.getUnmuteBtn()).visible, true, 'there is no unmute in case 3');
      s.softAssertEquals((row.getPinBtn()).visible, true, 'there is no pin in case 3');
      s.softAssertEquals((row.getUnreadBtn()).visible, false, 'there is UnRead in case 3');
      s.softAssertEquals((row.getMuteBtn()).visible, false, 'there is mute in case 3');
      s.softAssertEquals((row.getUnpinBtn()).visible, false, 'there is inpin in case 3');

      // unpin unmute
      //swipe a chat co tin mơi
      await row.unmute();
      await ChatScenario($).leftSwipe(groupTest);
      //verify the display of buttons
      s.softAssertEquals((row.getReadBtn()).visible, true, 'there is no Read in case 3');
      s.softAssertEquals((row.getMuteBtn()).visible, true, 'there is no mute in case 3');
      s.softAssertEquals((row.getPinBtn()).visible, true, 'there is no pin in case 3');
      s.softAssertEquals((row.getUnreadBtn()).visible, false, 'there is UnRead in case 3');
      s.softAssertEquals((row.getUnmuteBtn()).visible, false, 'there is unmute in case 3');
      s.softAssertEquals((row.getUnpinBtn()).visible, false, 'there is inpin in case 3');

      await ChatScenario($).rightSwipe(groupTest);
      s.verifyAll();
    },
  );
}
