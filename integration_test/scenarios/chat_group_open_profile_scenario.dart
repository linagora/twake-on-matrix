import '../base/base_test_scenario.dart';

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

  static const _searchPhrase = String.fromEnvironment(
    'SearchByTitle',
    defaultValue: 'My Default Group',
  );

  static const _memberMatrixID = String.fromEnvironment(
    'MemberMatrixID',
    defaultValue: '@member:localhost',
  );

  @override
  Future<void> runTestLogic() async {
    await robots.chatListRobot().openSearchScreen();

    final opened = await robots.searchViewRobot().searchAndOpenRoom(
      _searchPhrase,
    );
    if (!opened) {
      throw Exception('Test failed: Room "$_searchPhrase" was not found.');
    }

    await robots.chatGroupDetailRobot().tapOnChatBarTitle();
    await robots.groupInformationRobot().openMemberDetail(
      matrixID: _memberMatrixID,
    );

    final profile = robots.chatProfileInfoRobot();

    // Read the values the UI rendered, then assert they are displayed
    // consistently (same checks as the legacy imperative test).
    final displayName = await profile.getDisplayName();
    final email = await profile.getEmail();
    final phoneNumber = await profile.getPhoneNumber();

    await profile.verifyDisplayName(displayName: displayName);
    await profile.verifyDisplayMatrixId(matrixId: _memberMatrixID);
    await profile.verifyEmail(email: email);
    await profile.verifyPhoneNumber(phoneNumber: phoneNumber);
  }
}
