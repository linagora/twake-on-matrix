import '../../base/test_base.dart';
import '../../robots/chat/chat_profile_info_robot.dart';
import '../../robots/chat_list_robot.dart';
import '../../robots/group_information_robot.dart';
import '../../robots/search/search_view_robot.dart';
import '../../scenarios/chat_scenario.dart';

const defaultTime = Duration(seconds: 60);
const searchPhrase = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'My Default Group',
);
const forwardReceiver = String.fromEnvironment(
  'Receiver',
  defaultValue: 'Receiver Group',
);

int uniqueId() => DateTime.now().microsecondsSinceEpoch;

void main() {
  TestBase().twakePatrolTest(
    description: 'Chat group open  owner profile test',
    test: ($) async {
      const matrixID = "@stgtest:stg.lin-saas.com";
      await ChatListRobot($).openSearchScreen();

      final room = await SearchViewRobot($).searchRoom(searchPhrase);

      // Check if room was found and opened
      if (room == null) {
        throw Exception('Test failed: Room "$searchPhrase" was not found. ');
      }

      await SearchViewRobot($).openRoom(room);

      await ChatScenario($).openGroupChatInfo();

      await GroupInformationRobot($).openMemberDetail(matrixID: matrixID);

      // Get data from UI
      final displayName = await ChatProfileInfoRobot($).getDisplayName();

      final email = await ChatProfileInfoRobot($).getEmail();

      final phoneNumber = await ChatProfileInfoRobot($).getPhoneNumber();

      await ChatProfileInfoRobot($).verifyDisplayName(displayName: displayName);

      await ChatProfileInfoRobot($).verifyDisplayMatrixId(matrixId: matrixID);

      await ChatProfileInfoRobot($).verifyEmail(email: email);

      await ChatProfileInfoRobot($).verifyPhoneNumber(phoneNumber: phoneNumber);
    },
  );
}
