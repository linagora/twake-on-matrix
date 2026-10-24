import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';
import '../robots/emoji_picker_robot.dart';
import '../robots/message_reactions_robot.dart';

const _webGroup = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'My Default Group',
);

const _quickEmoji = '👍';
const _pickerEmoji = '🎉';
const _pickerKeyword = 'tada';

int _uid() => DateTime.now().microsecondsSinceEpoch;

/// Reactions need a group: direct chats hide reaction counts and details.
abstract class _ReactionsScenario extends BaseTestScenario {
  _ReactionsScenario(super.$, super.robots);

  Future<String> resolveGroupTitle();

  Future<String> openGroupAndSendMessage(String prefix) async {
    final group = await resolveGroupTitle();
    await robots.chatListRobot().openSearchScreen();
    final isRoomOpened = await robots.searchViewRobot().searchAndOpenRoom(
      group,
    );
    if (!isRoomOpened) {
      throw Exception('Test failed: Room "$group" was not found.');
    }
    await $.pump(const Duration(seconds: 1));

    final message = '$prefix ${_uid()}';
    await robots.chatGroupDetailRobot().sendMessage(message);
    final finder = await robots.chatGroupDetailRobot().getText(message);
    await $.waitUntilVisible(finder, timeout: const Duration(seconds: 30));
    return message;
  }
}

abstract class _QuickReactionScenario extends _ReactionsScenario {
  _QuickReactionScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final message = await openGroupAndSendMessage('quick-reaction');
    final menu = robots.messageMenuRobot();

    await menu.reactWithQuickEmoji(message, _quickEmoji);
    await MessageReactionsRobot($).expectReactionUnder(message, _quickEmoji);

    await menu.reactWithQuickEmoji(message, _quickEmoji);
    await MessageReactionsRobot($).expectNoReactionUnder(message, _quickEmoji);
  }
}

abstract class _PickerReactionScenario extends _ReactionsScenario {
  _PickerReactionScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final message = await openGroupAndSendMessage('picker-reaction');
    final menu = robots.messageMenuRobot();
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

    await menu.openFullEmojiPicker(message);
    await picker.waitUntilVisible();
    await picker.expectFirstInRecent(_pickerEmoji);
    await picker.close();
  }
}

class MobileQuickReactionScenario extends _QuickReactionScenario {
  MobileQuickReactionScenario(super.$, super.robots);

  @override
  Future<String> resolveGroupTitle() async =>
      (await prepareMobileGroupFixture(this)).title;
}

class MobilePickerReactionScenario extends _PickerReactionScenario {
  MobilePickerReactionScenario(super.$, super.robots);

  @override
  Future<String> resolveGroupTitle() async =>
      (await prepareMobileGroupFixture(this)).title;
}

class WebQuickReactionScenario extends _QuickReactionScenario {
  WebQuickReactionScenario(super.$, super.robots);

  @override
  Future<String> resolveGroupTitle() async => _webGroup;
}

class WebPickerReactionScenario extends _PickerReactionScenario {
  WebPickerReactionScenario(super.$, super.robots);

  @override
  Future<String> resolveGroupTitle() async => _webGroup;
}
