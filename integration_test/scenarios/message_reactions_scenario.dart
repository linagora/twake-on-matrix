import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';
import '../robots/emoji_picker_robot.dart';
import '../robots/message_menu_robot.dart';
import '../robots/message_reactions_robot.dart';

const _quickEmoji = '👍';
const _pickerEmoji = '🎉';
const _pickerKeyword = 'tada';

int _uid() => DateTime.now().microsecondsSinceEpoch;

/// Reactions need a group: direct chats hide reaction counts and details.
Future<String> _openGroupAndSendMessage(
  BaseTestScenario scenario,
  String prefix,
) async {
  final robots = scenario.robots;
  await openMobileGroupFixture(scenario);

  final message = '$prefix ${_uid()}';
  await robots.chatGroupDetailRobot().sendMessage(message);
  final finder = await robots.chatGroupDetailRobot().getText(message);
  await scenario.$.waitUntilVisible(
    finder,
    timeout: const Duration(seconds: 30),
  );
  return message;
}

class QuickReactionScenario extends BaseTestScenario {
  QuickReactionScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final message = await _openGroupAndSendMessage(this, 'quick-reaction');
    final menu = MessageMenuRobot($);

    await menu.reactWithQuickEmoji(message, _quickEmoji);
    await MessageReactionsRobot($).expectReactionUnder(message, _quickEmoji);

    await menu.reactWithQuickEmoji(message, _quickEmoji);
    await MessageReactionsRobot($).expectNoReactionUnder(message, _quickEmoji);
  }
}

class PickerReactionScenario extends BaseTestScenario {
  PickerReactionScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final message = await _openGroupAndSendMessage(this, 'picker-reaction');
    final menu = MessageMenuRobot($);
    final picker = EmojiPickerRobot($);

    // Recents persist across runs, so check the order changes in this run.
    await menu.reactWithQuickEmoji(message, _quickEmoji);
    await MessageReactionsRobot($).expectReactionUnder(message, _quickEmoji);

    await menu.openFullEmojiPicker(message);
    await picker.waitUntilVisible();
    await picker.expectFirstInRecent(_quickEmoji);
    await picker.search(_pickerKeyword);
    await picker.tapEmoji(_pickerEmoji);
    await MessageReactionsRobot($).expectReactionUnder(message, _pickerEmoji);
    await MessageReactionsRobot($).expectNoReactionUnder(message, _quickEmoji);

    await menu.openFullEmojiPicker(message);
    await picker.waitUntilVisible();
    await picker.expectFirstInRecent(_pickerEmoji);
    await picker.close();
  }
}
