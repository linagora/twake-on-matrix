import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/message_context_menu_robot.dart';
import '../../robots/home_robot.dart';
import '../../scenarios/chat_scenario.dart';

/// Integration test for verifying SafeArea and scrollability
/// in the message context menu dialog.
///
/// This test verifies the fix for the context menu overflow issue by checking:
/// 1. SafeArea wraps the dialog content and respects all insets
/// 2. SingleChildScrollView enables scrolling with ClampingScrollPhysics
/// 3. Content can scroll to top and bottom positions
void main() {
  TestBase().runPatrolTest(
    description: 'Message context menu has SafeArea and can scroll',
    test: ($) async {
      final s = SoftAssertHelper();
      const searchPhrase = String.fromEnvironment(
        'SearchByTitle',
        defaultValue: 'My Default Group',
      );

      // Step 1: Going to chat group
      await HomeRobot($).gotoChatListScreen();
      final chatDetail = await ChatScenario($).openChatGroup(searchPhrase);
      await $.pumpAndSettle();

      // Step 2: Send long message
      final longMessage =
          'This is a very long test message to ensure the context menu dialog has enough content to potentially overflow on small screens. '
          'Testing SafeArea and scrollability features with a message that contains multiple lines and lots of text content. '
          'This helps verify proper overflow handling in various scenarios including devices with different screen sizes. '
          'The context menu should remain accessible and usable even when the message preview takes up significant vertical space. '
          'All menu items should be reachable through smooth scrolling. '
          'Timestamp: ${DateTime.now().millisecondsSinceEpoch}';

      await ChatScenario($).sendAMesage(longMessage);
      await ChatScenario($).verifyMessageIsShown(longMessage, true);

      // Step 3: Hover on this message (open context menu by long pressing)
      await chatDetail.openPullDownMenu(longMessage);
      await $.pumpAndSettle();

      final menuRobot = MessageContextMenuRobot($);
      await menuRobot.waitForDialogToAppear();

      // Verify SafeArea exists
      s.softAssertEquals(
        menuRobot.getSafeArea().exists,
        true,
        'SafeArea should wrap dialog content',
      );

      // Verify SingleChildScrollView exists inside SafeArea
      await menuRobot.verifySafeAreaHierarchy();

      // Verify ClampingScrollPhysics is used
      await menuRobot.verifyClampingScrollPhysics();

      // Replace the safeAreas loop entirely with:
      await menuRobot.verifySafeAreaInsets();
      s.softAssertEquals(
        menuRobot.getSafeArea().exists,
        true,
        'Dialog SafeArea should be found',
      );

      // Verify at least one menu item is visible
      s.softAssertEquals(
        menuRobot.getReplyItem().visible ||
            menuRobot.getForwardItem().visible ||
            menuRobot.getCopyItem().visible,
        true,
        'At least one menu item should be visible',
      );

      // Test scrolling to bottom — verify a "late" item becomes visible
      await menuRobot.scrollDialogToBottom();
      await $.pumpAndSettle();

      s.softAssertEquals(
        menuRobot.getSelectItem().visible ||
            menuRobot.getPinItem(isPinned: true).visible,
        true,
        'Select or Pin item should be visible after scrolling to bottom',
      );

      // Test scrolling to top — verify the first item is visible again
      await menuRobot.scrollDialogToTop();
      await $.pumpAndSettle();

      s.softAssertEquals(
        menuRobot.getReplyItem().visible || menuRobot.getForwardItem().visible,
        true,
        'Reply or Forward item should be visible after scrolling to top',
      );

      // Close dialog
      await menuRobot.closeByTappingBackdrop();

      s.verifyAll();
    },
  );
}
