import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../robots/chat_list_robot.dart';
import '../../scenarios/chat_scenario.dart';
import '../../robots/home_robot.dart';

void main() {
  // TestBase().runPatrolTest(
  //   description: 'verify display of New Chat screen',
  //   test: ($) async {
  //     final s = SoftAssertHelper();
  //     // goto chat screen
  //     await HomeRobot($).gotoChatListScreen();
  //     // click on Pen icon
  //     await ChatListRobot($).clickOnPenIcon();
  //     // verify Title, search Icon, back icon, "New Group Chat" button is avalable
  //     s.softAssertEquals(NewChatRobot($).getNewGroupChatIcon().exists, true, 'New Group Chat button is not displayed');
  //     s.softAssertEquals(NewChatRobot($).getSearchIcon().exists, true, 'SearchIcon is not shown');
  //     s.softAssertEquals(NewChatRobot($).getBackIcon().exists, true, 'Back icon is missing');
  //     s.verifyAll();
  //   },
  // );

  TestBase().runPatrolTest(
    description: 'create a new group chat',
    test: ($) async {
      final s = SoftAssertHelper();
      const searchByMatrixAddress = String.fromEnvironment(
        'SearchByMatrixAddress',
      );
      final now = DateTime.now();
      final groupName =
          "${now.year}${now.month}${now.day}${now.hour}${now.minute}";

      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // click on Pen icon
      await ChatScenario($).createANewGroupChat(groupName, [
        searchByMatrixAddress,
      ], searchKey: searchByMatrixAddress);
      // verify group is shown with correct name, back iocn, search icon and more icon
      s.softAssertEquals(
        ChatGroupDetailRobot($).getBackIcon().exists,
        true,
        'Back icon is missing',
      );
      s.softAssertEquals(
        ChatGroupDetailRobot($).getSearchIcon().exists,
        true,
        'Search icon is missing',
      );
      s.softAssertEquals(
        ChatGroupDetailRobot($).getMoreIcon().exists,
        true,
        'More icon is missing',
      );
      s.softAssertEquals(
        $(ChatAppBarTitle).$(groupName).exists,
        true,
        'Group name is not correct',
      );

      //click button back
      await ChatScenario($).backToChatLisFromChatGroupScreen();

      //verify new group is listed
      final group = ChatListRobot($).getChatGroupByTitle(groupName);
      s.softAssertEquals(
        group.root.exists,
        true,
        "the new group $groupName is not listed",
      );
      s.verifyAll();
    },
  );

  //todo: update this script later
  // TestBase().runPatrolTest(
  //   description: 'verify the display on Group Infomation Screen',
  //   test: ($) async {
  //     final s = SoftAssertHelper();
  //     const groupTest = String.fromEnvironment('GroupTest');
  //     // goto chat screen
  //     await HomeRobot($).gotoChatListScreen();
  //     // open GroupTest
  //     await ChatScenario($).openChatGroupByTitle(groupTest);
  //     //open group chat info
  //     await ChatScenario($).openGroupChatInfo();
  //     //verify the display of info screen
  //     s.softAssertEquals(GroupInformationRobot($).getBackIcon().exists, true, 'Back btn is mising');
  //     s.softAssertEquals(GroupInformationRobot($).getEditTitleIcon().exists, true, 'Edit btn is mising',);
  //     s.softAssertEquals(GroupInformationRobot($).getNotificationToggle().exists, true, 'Notification btn is mising');
  //     s.softAssertEquals(GroupInformationRobot($).getMemberTab().exists, true, 'Member tab is mising');
  //     s.softAssertEquals(GroupInformationRobot($).getMediaTab().exists, true, 'Media tab is mising');
  //     s.softAssertEquals(GroupInformationRobot($).getLinksTab().exists, true, 'Link tab is mising');
  //     s.softAssertEquals(GroupInformationRobot($).getFilesTab().exists, true, 'Files tab is mising');
  //     s.softAssertEquals(GroupInformationRobot($).getAddMembersBtn().exists, true, 'Add member button is mising',);

  //     s.verifyAll();
  //   },
  // );

  //todo: update this tc base on confirm adding a user
  // TestBase().runPatrolTest(
  //   description: 'change member of a group',
  //   test: ($) async {
  //     final s = SoftAssertHelper();
  //     const groupTest = String.fromEnvironment('GroupTest');
  //     const user3 = String.fromEnvironment('User3MaxtrixAddress');
  //     // goto chat screen
  //     await HomeRobot($).gotoChatListScreen();
  //     // open GroupTest
  //     await ChatScenario($).openChatGroupByTitle(groupTest);
  //     final numberOFMemberBeforeAdding = ChatGroupDetailRobot($).getTotalMemberLabel();

  //     // add more one member
  //     final totalMemberAfterAdding = await ChatScenario($).addMembers([user3]);
  //     // verify added user listed under Memmber tab of GroupInformation screen
  //     s.softAssertEquals(GroupInformationRobot($).getMember(user3).exists, true, "added member is not listed",);
  //     s.softAssertEquals(GroupInformationRobot($).getTotalMemberLabel() ==
  //             totalMemberAfterAdding.toString(), true, "total of number is correct",);
  //     //Click back button on GroupInformation screen
  //     await GroupInformationRobot($).clickOnBackBtn();
  //     s.softAssertEquals( totalMemberAfterAdding.toString() == (int.parse(numberOFMemberBeforeAdding) + 1).toString(),
  //         true, "number of member is not updated",);

  //     //remove a member
  //     await ChatScenario($).removeMembers([user3]);
  //     final totalMemberAfterRemoving = GroupInformationRobot($).getTotalMemberLabel();
  //     // verify removed member is not listed under Memmber tab of GroupInformation screen
  //     s.softAssertEquals(GroupInformationRobot($).getMember(user3).exists, false, "removed member still listed",);
  //     s.softAssertEquals(GroupInformationRobot($).getTotalMemberLabel() ==
  //             totalMemberAfterRemoving.toString(), true, "total of number is correct",);
  //     //Click back button on GroupInformation screen
  //     await GroupInformationRobot($).clickOnBackBtn();
  //     //verify number of member is updated on Group Title
  //     final expectNumber = totalMemberAfterAdding - 1;
  //     s.softAssertEquals(totalMemberAfterRemoving == expectNumber.toString(), true, "number of member is not updated. Expect $totalMemberAfterRemoving but Actual is $expectNumber",);

  //     s.verifyAll();
  //   },
  // );
}
