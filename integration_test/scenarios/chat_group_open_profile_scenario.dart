import 'package:flutter/foundation.dart';

import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';

/// Cross-platform scenario: open a group member's profile and verify the
/// displayed identity fields.
///
/// Searches the group named by `SearchByTitle`, opens its group info,
/// drills into the member identified by `MemberMatrixID` and checks that
/// the display name, matrix id, email and phone number render consistently.
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`.
class ChatGroupOpenProfileScenario extends BaseTestScenario {
  ChatGroupOpenProfileScenario(super.$, super.robots);

  static const _webSearchPhrase = String.fromEnvironment(
    'SearchByTitle',
    defaultValue: 'My Default Group',
  );
  static const _memberMatrixID = String.fromEnvironment(
    'MemberMatrixID',
    defaultValue: '@member:localhost',
  );

  @override
  Future<void> runTestLogic() async {
    var searchPhrase = _webSearchPhrase;
    var memberMatrixID = _memberMatrixID;
    if (!kIsWeb) {
      final fixture = await prepareMobileGroupFixture(this);
      searchPhrase = fixture.title;
      memberMatrixID = fixture.memberMatrixId;
    }

    await robots.chatListRobot().openSearchScreen();

    final opened = await robots.searchViewRobot().searchAndOpenRoom(
      searchPhrase,
    );
    if (!opened) {
      throw Exception('Test failed: Room "$searchPhrase" was not found.');
    }

    await robots.chatGroupDetailRobot().tapOnChatBarTitle();
    await robots.groupInformationRobot().openMemberDetail(
      matrixID: memberMatrixID,
    );

    final profile = robots.chatProfileInfoRobot();

    // Read the values the UI rendered, then assert they are displayed
    // consistently (same checks as the legacy imperative test).
    final displayName = await profile.getDisplayName();
    final email = await profile.getEmail();
    final phoneNumber = await profile.getPhoneNumber();

    await profile.verifyDisplayName(displayName: displayName);
    await profile.verifyDisplayMatrixId(matrixId: memberMatrixID);
    await profile.verifyEmail(email: email);
    await profile.verifyPhoneNumber(phoneNumber: phoneNumber);
  }
}
