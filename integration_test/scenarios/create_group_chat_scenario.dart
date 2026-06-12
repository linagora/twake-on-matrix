import 'package:flutter_test/flutter_test.dart';

import '../base/base_test_scenario.dart';

/// Cross-platform scenario: create a new group chat.
///
/// Opens the new-group flow, adds the member matched by [_memberSearchKey],
/// names the group and confirms, then asserts the new group's chat view opens
/// with the chosen name.
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`.
class CreateGroupChatScenario extends BaseTestScenario {
  CreateGroupChatScenario(super.$, super.robots);

  static const _memberSearchKey = String.fromEnvironment(
    'SearchByMatrixAddress',
  );

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();

    final now = DateTime.now();
    final groupName =
        '${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}';

    await robots.chatListRobot().createGroupChat(groupName, _memberSearchKey);

    final detail = robots.chatGroupDetailRobot();
    expect(
      await detail.isVisible(),
      isTrue,
      reason: 'New group chat view is not shown',
    );
    expect(
      detail.getTitle(),
      groupName,
      reason: 'New group name is not correct',
    );
  }
}
