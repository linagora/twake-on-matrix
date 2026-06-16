import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/home_robot.dart';
import '../robots/message_context_menu_robot.dart';
import 'chat_scenario.dart';

/// Mobile-only: verify the long-press message context menu (`PullDownMenu`)
/// wraps its content in a scrollable `SafeArea`. The dialog and its internals
/// only exist on mobile (web uses a hover action bar), so the test is
/// registered with `mobileOnly: true` and skipped on web. Drives the concrete
/// mobile robots directly.
class MessageContextMenuSafeAreaScenario extends BaseTestScenario {
  MessageContextMenuSafeAreaScenario(super.$, super.robots);

  static const _searchPhrase = String.fromEnvironment(
    'SearchByTitle',
    defaultValue: 'My Default Group',
  );

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();

    // Step 1: open the chat group.
    await HomeRobot($).gotoChatListScreen();
    final chatDetail = await ChatScenario($).openChatGroup(_searchPhrase);
    await $.pumpAndSettle();

    // Step 2: send a long message so the context menu can overflow.
    final longMessage =
        'This is a very long test message to ensure the context menu dialog has enough content to potentially overflow on small screens. '
        'Testing SafeArea and scrollability features with a message that contains multiple lines and lots of text content. '
        'This helps verify proper overflow handling in various scenarios including devices with different screen sizes. '
        'The context menu should remain accessible and usable even when the message preview takes up significant vertical space. '
        'All menu items should be reachable through smooth scrolling. '
        'Timestamp: ${DateTime.now().millisecondsSinceEpoch}';

    await ChatScenario($).sendAMesage(longMessage);
    await ChatScenario($).verifyMessageIsShown(longMessage, true);

    // Step 3: open the context menu via long press.
    await chatDetail.openPullDownMenu(longMessage);
    await $.pumpAndSettle();

    final menuRobot = MessageContextMenuRobot($);
    await menuRobot.waitForDialogToAppear();

    s.softAssertEquals(
      menuRobot.getSafeArea().exists,
      true,
      'SafeArea should wrap dialog content',
    );
    await menuRobot.verifySafeAreaHierarchy();
    await menuRobot.verifyClampingScrollPhysics();
    await menuRobot.verifySafeAreaInsets();
    s.softAssertEquals(
      menuRobot.getSafeArea().exists,
      true,
      'Dialog SafeArea should be found',
    );

    s.softAssertEquals(
      menuRobot.getReplyItem().visible ||
          menuRobot.getForwardItem().visible ||
          menuRobot.getCopyItem().visible,
      true,
      'At least one menu item should be visible',
    );

    await menuRobot.scrollDialogToBottom();
    await $.pumpAndSettle();
    s.softAssertEquals(
      menuRobot.getSelectItem().visible ||
          menuRobot.getPinItem(isPinned: true).visible,
      true,
      'Select or Pin item should be visible after scrolling to bottom',
    );

    await menuRobot.scrollDialogToTop();
    await $.pumpAndSettle();
    s.softAssertEquals(
      menuRobot.getReplyItem().visible || menuRobot.getForwardItem().visible,
      true,
      'Reply or Forward item should be visible after scrolling to top',
    );

    await menuRobot.closeByTappingBackdrop();
    s.verifyAll();
  }
}
