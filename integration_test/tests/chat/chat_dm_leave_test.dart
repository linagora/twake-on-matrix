import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/chat/chat_profile_info_robot.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../robots/chat_list_robot.dart';
import '../../robots/search_robot.dart';
import '../../scenarios/chat_scenario.dart';
import '../../robots/home_robot.dart';

// Timeout constants for consistent behavior
const _kNavigationTimeout = Duration(seconds: 5);

// Generate unique timestamp-based account for each test run
String generateTimestampAccount() {
  final now = DateTime.now();
  const serverUrl = String.fromEnvironment('SERVER_URL');
  if (serverUrl.isEmpty) {
    throw StateError(
      'SERVER_URL environment variable is not set. '
      'Please provide it via --dart-define=SERVER_URL=your-server',
    );
  }
  return '@user${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}:$serverUrl';
}

void main() {
  TestBase().runPatrolTest(
    description:
        'Leave DM chat - Create DM, send message, verify chat list, leave, verify removal',
    test: ($) async {
      final s = SoftAssertHelper();
      final timestampAccount = generateTimestampAccount();
      final now = DateTime.now();
      final testMessage =
          'Test message ${now.hour}:${now.minute}:${now.second}';

      // Step 1: Create DM chat with timestamp account
      await HomeRobot($).gotoChatListScreen();
      await ChatScenario($).createANewDirectMessage(timestampAccount);

      // Verify chat screen is shown
      s.softAssertEquals(
        $(ChatView).exists || $(DraftChatView).exists,
        true,
        'Chat view or draft chat view is not shown',
      );

      // Step 2: Send 1 message
      await ChatScenario($).sendAMesage(testMessage);

      // Verify message is sent
      await ChatScenario($).verifyMessageIsShown(testMessage, true);
      await ChatScenario($).verifyMessageIsSent(testMessage, true);

      // Step 3: Navigate back to chat list and verify chat exists
      await ChatScenario($).backToChatLisFromChatGroupScreen();
      await $.pumpAndSettle(timeout: _kNavigationTimeout);

      final chatListRobot = ChatListRobot($);
      final chatExists = $(TwakeListItem).exists;
      s.softAssertEquals(chatExists, true, 'Chat is not visible in chat list');

      // Step 4: Search for the chat and open it to try to leave
      await chatListRobot.openSearchScreenWithoutAcceptPermission();

      final searchRobot = SearchRobot($);
      await searchRobot.enterSearchText(timestampAccount);

      // Wait for search results to appear instead of pumpAndSettle
      // (pumpAndSettle times out due to TextField cursor animation)
      await $.waitUntilVisible($(TwakeListItem), timeout: _kNavigationTimeout);

      // Verify search result exists
      s.softAssertEquals(
        $(TwakeListItem).exists,
        true,
        'Chat is not found in search results',
      );

      // Open the chat from search results
      await $(TwakeListItem).first.tap();
      await $.waitUntilVisible($(ChatView));

      // Open chat profile info (DM-specific method)
      await ChatGroupDetailRobot($).tapOnChatBarTitleForDM();

      // Step 5: Verify leave button is visible
      final profileInfoRobot = ChatProfileInfoRobot($);
      final leaveChatButton = profileInfoRobot.getLeaveChatButton();
      s.softAssertEquals(
        leaveChatButton.exists,
        true,
        'Leave chat button is not visible',
      );

      // Tap on leave button
      await profileInfoRobot.tapLeaveChatButton();

      // Verify confirm dialog is shown
      await profileInfoRobot.verifyLeaveChatConfirmDialog();

      // Confirm leaving the chat
      await profileInfoRobot.confirmLeaveChat();

      // Wait for navigation back to chat list
      await $.pumpAndSettle(timeout: _kNavigationTimeout);

      // Step 6: Verify chat is removed from the list
      s.softAssertEquals(
        chatListRobot.getChatGroupByTitle(timestampAccount).root.exists,
        false,
        'Chat still exists in chat list after leaving',
      );

      s.verifyAll();
    },
  );
}
