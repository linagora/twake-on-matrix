import 'package:flutter/foundation.dart';
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
/// On web the fixture is the isolated room named by `SearchByTitle`; on mobile
/// it is the in-app group fixture, because the shared staging account has no
/// `SearchByTitle` room.
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`, so the same scenario runs on mobile and web.
class SendMessageScenario extends BaseTestScenario {
  SendMessageScenario(super.$, super.robots);

  static const _webSearchPhrase = String.fromEnvironment(
    'SearchByTitle',
    defaultValue: 'My Default Group',
  );

  @override
  Future<void> runTestLogic() async {
    String? roomId;

    if (!kIsWeb) {
      final fixture = await prepareMobileGroupFixture(this);
      await robots.chatListRobot().openSearchScreen();
      final opened = await robots.searchViewRobot().searchAndOpenRoom(
        fixture.title,
      );
      if (!opened) {
        throw Exception('Test failed: Room "${fixture.title}" was not found.');
      }
      roomId = fixture.roomId;
    } else {
      await robots.homeRobot().gotoChatListScreen();
      await robots.searchRobot().enterSearchText(_webSearchPhrase);
      await $.pump();
      await robots.chatListRobot().openChatGroupByIndex(0);
    }

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
