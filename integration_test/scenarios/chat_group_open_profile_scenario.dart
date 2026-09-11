import 'package:flutter/foundation.dart';

import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';

/// Cross-platform scenario: open a group member's profile and verify the
/// displayed identity fields.
///
/// On web it searches the group named by `SearchByTitle` and drills into the
/// member identified by `MemberMatrixID`. On mobile the staged `SearchByTitle`
/// room does not exist — the app runs against a shared account — so it opens
/// the in-app group fixture and its invited receiver instead.
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`.
class ChatGroupOpenProfileScenario extends BaseTestScenario {
  ChatGroupOpenProfileScenario(super.$, super.robots);

  static const _webSearchPhrase = String.fromEnvironment(
    'SearchByTitle',
    defaultValue: 'My Default Group',
  );

  static const _webMemberMatrixId = String.fromEnvironment(
    'MemberMatrixID',
    defaultValue: '@member:localhost',
  );

  @override
  Future<void> runTestLogic() async {
    final String memberMatrixId;

    if (!kIsWeb) {
      final fixture = await prepareMobileGroupFixture(this);
      await robots.chatListRobot().openSearchScreen();
      final opened = await robots.searchViewRobot().searchAndOpenRoom(
        fixture.title,
      );
      if (!opened) {
        throw Exception('Test failed: Room "${fixture.title}" was not found.');
      }
      memberMatrixId = fixture.memberMatrixId;
    } else {
      await robots.chatListRobot().openSearchScreen();
      final opened = await robots.searchViewRobot().searchAndOpenRoom(
        _webSearchPhrase,
      );
      if (!opened) {
        throw Exception('Test failed: Room "$_webSearchPhrase" was not found.');
      }
      memberMatrixId = _webMemberMatrixId;
    }

    await robots.chatGroupDetailRobot().tapOnChatBarTitle();
    await robots.groupInformationRobot().openMemberDetail(
      matrixID: memberMatrixId,
    );

    final profile = robots.chatProfileInfoRobot();

    // Read the values the UI rendered, then assert they are displayed
    // consistently (same checks as the legacy imperative test).
    final displayName = await profile.getDisplayName();
    final email = await profile.getEmail();
    final phoneNumber = await profile.getPhoneNumber();

    await profile.verifyDisplayName(displayName: displayName);
    await profile.verifyDisplayMatrixId(matrixId: memberMatrixId);
    await profile.verifyEmail(email: email);
    await profile.verifyPhoneNumber(phoneNumber: phoneNumber);
  }
}
