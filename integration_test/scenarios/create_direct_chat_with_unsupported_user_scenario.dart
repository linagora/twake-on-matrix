import 'package:flutter_test/flutter_test.dart';

import '../base/base_test_scenario.dart';

/// Cross-platform scenario: an unsupported Matrix ID never creates a room.
///
/// Searches the chat list for an address on an unreachable homeserver. The two
/// platforms surface this differently, so the scenario branches on the observed
/// result state (never on `kIsWeb`):
///
/// - Mobile offers an external draft tile; opening it and trying to send must
///   not persist a room.
/// - Web offers no actionable tile, so no room can be created.
///
/// In both cases the chat-list room count must be unchanged. The post-search
/// reset also differs per state: mobile backs out of the search screen, web
/// clears the inline search via a navigation round-trip.
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`.
class CreateDirectChatWithUnsupportedUserScenario extends BaseTestScenario {
  CreateDirectChatWithUnsupportedUserScenario(super.$, super.robots);

  static const _unsupportedMxid = '@awsd:awsd.com';

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();
    final before = await robots.chatListRobot().getChatRoomCounts();

    await robots.searchRobot().enterSearchText(_unsupportedMxid);
    await _settleSearch();

    final results = await robots.chatListRobot().getListOfChatGroup();
    if (results.isNotEmpty) {
      // A draft tile is offered (mobile): opening it and sending must fail.
      await robots.chatListRobot().openChatGroupByIndex(0);
      await robots.chatGroupDetailRobot().sendMessage('hello');
      await $.pump(const Duration(seconds: 2));
      await robots.chatGroupDetailRobot().clickOnBackIcon();
      await robots.searchRobot().backToPreviousScreen();
    } else {
      // No actionable result (web): clear the inline search via a tab
      // round-trip so the full list is countable again.
      await robots.homeRobot().gotoContactListScreen();
      await robots.homeRobot().gotoChatListScreen();
    }
    await $.pump();

    final after = await robots.chatListRobot().getChatRoomCounts();
    expect(
      after,
      before,
      reason: 'Messaging an unsupported user must not create a room',
    );
  }

  /// Briefly polls for result rows to render (the homeserver lookup is async).
  Future<void> _settleSearch() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 300));
      if ((await robots.chatListRobot().getListOfChatGroup()).isNotEmpty) return;
    }
  }
}
