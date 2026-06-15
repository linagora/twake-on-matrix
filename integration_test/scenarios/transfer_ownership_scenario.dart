import 'package:fluffychat/presentation/enum/profile_info/profile_info_body_enum.dart';

import '../base/base_test_scenario.dart';

/// Cross-platform scenario: transfer group ownership to a member and verify
/// the action disappears afterwards.
///
/// Pre-condition: the logged-in account owns the group named by
/// `SearchByTitle` and `MemberMatrixID` is a joined member. Note the action
/// mutates server state — re-running against the same homeserver without
/// re-provisioning leaves the account without ownership.
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`.
class TransferOwnershipScenario extends BaseTestScenario {
  TransferOwnershipScenario(super.$, super.robots);

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
    // 1. Open the group chat.
    await robots.chatListRobot().openSearchScreen();
    final opened = await robots.searchViewRobot().searchAndOpenRoom(
      _searchPhrase,
    );
    if (!opened) {
      throw Exception('Test failed: Room "$_searchPhrase" was not found.');
    }

    // 2. Open group info and navigate to a member's profile.
    await robots.chatGroupDetailRobot().tapOnChatBarTitle();
    await robots.groupInformationRobot().openMemberDetail(
      matrixID: _memberMatrixID,
    );

    final profile = robots.chatProfileInfoRobot();

    // 3. Verify transfer ownership button is visible (current user is owner).
    await profile.verifyProfileActionButtonVisible(
      ProfileInfoActions.transferOwnership,
    );

    // 4. Tap transfer ownership and confirm.
    await profile.tapProfileActionButton(ProfileInfoActions.transferOwnership);
    await profile.confirmTransferOwnership();

    // 5. Wait for the operation to complete and the profile page to pop.
    await $.pump(const Duration(seconds: 3));

    // 6. After transfer, the profile page pops back to Group Info.
    //    Re-open the same member's profile to verify the button is gone.
    await robots.groupInformationRobot().openMemberDetail(
      matrixID: _memberMatrixID,
    );
    await profile.verifyProfileActionButtonVisible(
      ProfileInfoActions.transferOwnership,
      expected: false,
    );
  }
}
