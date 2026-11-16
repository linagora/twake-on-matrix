import 'package:flutter_test/flutter_test.dart';

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';

/// Cross-platform scenario for sending a message in a group chat.
///
/// Opens the platform fixture group, sends one message from the current account
/// through the UI and one as the receiver through the API, then asserts both
/// render in the timeline.
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`.
class SendMessageScenario extends BaseTestScenario {
  SendMessageScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await prepareMobileGroupFixture(this);
    await robots.chatListRobot().openSearchScreen();
    final opened = await robots.searchViewRobot().searchAndOpenRoom(
      fixture.title,
    );
    if (!opened) {
      throw Exception('Test failed: Room "${fixture.title}" was not found.');
    }
    final roomId = fixture.roomId;

    final now = DateTime.now();
    final stamp = '${now.year}${now.month}${now.day}${now.hour}${now.minute}';
    final messageOfSender = 'sender sent at $stamp';
    final messageOfReceiver = 'receiver sent at $stamp';

    // Send via the UI and verify it appears.
    await robots.chatGroupDetailRobot().sendMessage(messageOfSender);
    await _verifyShown(messageOfSender);

    // Send as the receiver via the API and verify it appears.
    await sendMessageAsReceiver(message: messageOfReceiver, roomId: roomId);
    await _verifyShown(messageOfReceiver);
  }

  Future<void> _verifyShown(String message) async {
    final text = await robots.chatGroupDetailRobot().getText(message);
    await $.waitUntilVisible(text);
    expect(text, findsOneWidget);
  }
}
