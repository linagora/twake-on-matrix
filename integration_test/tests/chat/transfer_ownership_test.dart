import 'package:fluffychat/presentation/enum/profile_info/profile_info_body_enum.dart';

import '../../base/test_base.dart';
import '../../robots/chat/chat_profile_info_robot.dart';
import '../../robots/chat_list_robot.dart';
import '../../robots/group_information_robot.dart';
import '../../robots/search/search_view_robot.dart';
import '../../scenarios/chat_scenario.dart';

const searchPhrase = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'My Default Group',
);

const memberMatrixID = String.fromEnvironment(
  'MemberMatrixID',
  defaultValue: '@member:localhost',
);

void main() {
  TestBase().runPatrolTest(
    tags: ['transfer_ownership_test_01'],
    description:
        'Transfer ownership button disappears after successful transfer',
    test: ($) async {
      // 1. Open the group chat
      await ChatListRobot($).openSearchScreen();
      final room = await SearchViewRobot($).searchRoom(searchPhrase);
      if (room == null) {
        throw Exception('Test failed: Room "$searchPhrase" was not found.');
      }
      await SearchViewRobot($).openRoom(room);

      // 2. Open group info and navigate to a member's profile
      await ChatScenario($).openGroupChatInfo();
      await GroupInformationRobot($).openMemberDetail(matrixID: memberMatrixID);

      // 3. Verify transfer ownership button is visible (current user is owner)
      await ChatProfileInfoRobot(
        $,
      ).verifyProfileActionButtonVisible(ProfileInfoActions.transferOwnership);

      // 4. Tap transfer ownership and confirm
      await ChatProfileInfoRobot(
        $,
      ).tapProfileActionButton(ProfileInfoActions.transferOwnership);
      await ChatProfileInfoRobot($).confirmTransferOwnership();

      // 5. Wait for the operation to complete and profile page to pop
      await $.pump(const Duration(seconds: 3));

      // 6. After transfer, the profile page pops back to Group Info.
      //    Re-open the same member's profile to verify the button is gone.
      await GroupInformationRobot($).openMemberDetail(matrixID: memberMatrixID);
      await ChatProfileInfoRobot($).verifyProfileActionButtonVisible(
        ProfileInfoActions.transferOwnership,
        expected: false,
      );
    },
  );
}
