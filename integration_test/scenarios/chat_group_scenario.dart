import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/event_info_dialog.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../robots/chat_group_detail_robot.dart';
import 'chat_scenario.dart';

const _group = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'My Default Group',
);

int _uid() => DateTime.now().microsecondsSinceEpoch;

/// Opens [_group], posts one message through the UI (sender) and one through
/// the API as the receiver, waits for both, and returns `(senderMsg,
/// receiverMsg)`.
///
/// Drives the UI exclusively through the abstract robots; the receiver message
/// is injected via the cross-platform `sendMessageAsReceiver` API helper so the
/// scenario has a message it does not own to act on.
Future<(String, String)> _prepareTwoMessages(BaseTestScenario scenario) async {
  final robots = scenario.robots;
  final $ = scenario.$;

  await robots.chatListRobot().openSearchScreen();
  final opened = await robots.searchViewRobot().searchAndOpenRoom(_group);
  if (!opened) {
    throw Exception('Test failed: Room "$_group" was not found.');
  }
  await $.pump(const Duration(seconds: 1));

  final id = _uid();
  final senderMsg = 'sender sent at $id';
  final receiverMsg = 'receiver sent at $id';

  await robots.chatGroupDetailRobot().sendMessage(senderMsg);
  await _waitShown(scenario, senderMsg);

  await sendMessageAsReceiver(message: receiverMsg);
  await _waitShown(scenario, receiverMsg);

  return (senderMsg, receiverMsg);
}

Future<void> _waitShown(BaseTestScenario scenario, String message) async {
  final chatGroupDetailRobot = scenario.robots.chatGroupDetailRobot();
  final finder = await chatGroupDetailRobot.getText(message);
  await scenario.$.waitUntilExists(
    finder,
    timeout: const Duration(seconds: 60),
  );
  // On web the timeline can build a newly sent message just outside the
  // hit-testable viewport. Move to the live edge after the event exists so the
  // visibility assertion cannot stall on an off-screen MessageContent.
  await chatGroupDetailRobot.scrollToLiveBottom();
  await scenario.$.waitUntilVisible(
    finder,
    timeout: const Duration(seconds: 60),
  );
}

Future<void> _waitAbsent(BaseTestScenario scenario, String message) async {
  final finder = await scenario.robots.chatGroupDetailRobot().getText(message);
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (finder.exists) {
    if (DateTime.now().isAfter(deadline)) {
      throw Exception('Message "$message" is still visible after deletion.');
    }
    await scenario.$.pump(const Duration(milliseconds: 200));
  }
}

/// Reply to a sender-owned and a receiver-owned message in a group chat.
class ChatGroupReplyScenario extends BaseTestScenario {
  ChatGroupReplyScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final (senderMsg, receiverMsg) = await _prepareTwoMessages(this);

    final replySender = 'reply sender at ${_uid()}';
    await robots.messageMenuRobot().openReply(senderMsg);
    await robots.chatGroupDetailRobot().sendMessage(replySender);
    await _waitShown(this, replySender);

    final replyReceiver = 'reply receiver at ${_uid()}';
    await robots.messageMenuRobot().openReply(receiverMsg);
    await robots.chatGroupDetailRobot().sendMessage(replyReceiver);
    await _waitShown(this, replyReceiver);
  }
}

/// Edit a sender-owned message in a group chat: the edited text appears and
/// the original text is gone.
class ChatGroupEditScenario extends BaseTestScenario {
  ChatGroupEditScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final (senderMsg, _) = await _prepareTwoMessages(this);

    // Distinct text (not a superstring of [senderMsg]) so the "original is
    // gone" check can't match the edited bubble under `textContaining`.
    final edited = 'edited sender at ${_uid()}';
    await robots.messageMenuRobot().openEdit(senderMsg);
    await robots.chatGroupDetailRobot().sendMessage(edited);

    await _waitShown(this, edited);
    await _waitAbsent(this, senderMsg);
  }
}

/// Select a message in a group chat and verify the multi-select mode is active
/// (the selection count surfaces in the chat app-bar title).
class ChatGroupSelectScenario extends BaseTestScenario {
  ChatGroupSelectScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final (senderMsg, _) = await _prepareTwoMessages(this);

    await robots.messageMenuRobot().openSelect(senderMsg);

    final count = $(ChatAppBarTitle).$(find.text('1'));
    await $.waitUntilVisible(count, timeout: const Duration(seconds: 10));
  }
}

/// Delete a sender-owned and a receiver-owned message in a group chat
/// (the logged-in account is an admin, so it can redact both).
class ChatGroupDeleteScenario extends BaseTestScenario {
  ChatGroupDeleteScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final (senderMsg, receiverMsg) = await _prepareTwoMessages(this);

    await robots.messageMenuRobot().openDelete(senderMsg);
    await _waitAbsent(this, senderMsg);

    await robots.messageMenuRobot().openDelete(receiverMsg);
    await _waitAbsent(this, receiverMsg);
  }
}

/// Mobile-only: verify the long-press pull-down menu surfaces the right actions
/// for a sender-owned (owner level) and a receiver-owned (member level)
/// message. The pull-down menu only exists on mobile, so this is registered
/// with `mobileOnly: true` and drives concrete robots directly.
class ChatGroupDisplayMenuScenario extends BaseTestScenario {
  ChatGroupDisplayMenuScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final (senderMsg, receiverMsg) = await _prepareTwoMessages(this);

    await ChatGroupDetailRobot($).openPullDownMenu(senderMsg);
    await ChatScenario(
      $,
    ).verifyTheDisplayOfPullDownMenu(senderMsg, level: UserLevel.owner);
    await ChatGroupDetailRobot($).closePullDownMenu();

    await ChatGroupDetailRobot($).openPullDownMenu(receiverMsg);
    await ChatScenario(
      $,
    ).verifyTheDisplayOfPullDownMenu(receiverMsg, level: UserLevel.member);
  }
}

/// Mobile-only: copy a sender-owned and a receiver-owned message and paste them
/// back into the composer, verifying the pasted text is sent. Uses the system
/// clipboard via concrete robots, so this is registered with `mobileOnly: true`.
class ChatGroupCopyScenario extends BaseTestScenario {
  ChatGroupCopyScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final (senderMsg, receiverMsg) = await _prepareTwoMessages(this);

    // copy sender
    await ChatScenario($).copyMessage(senderMsg);
    const addedText = 'Copy';
    await ChatGroupDetailRobot($).inputMessage(addedText);
    await ChatScenario($).pasteFromClipBoard();
    await $(ChatInputRowSendBtn).tap();
    await ChatScenario($).verifyMessageIsShown('$addedText$senderMsg', true);

    // copy receiver
    await ChatScenario($).copyMessage(receiverMsg);
    await ChatGroupDetailRobot($).inputMessage(addedText);
    await ChatScenario($).pasteFromClipBoard();
    await $(ChatInputRowSendBtn).tap();
    await ChatScenario($).verifyMessageIsShown('$addedText$receiverMsg', true);
  }
}

/// Open a message's info dialog and verify it shows the sender avatar and the
/// raw event source. Indices into the dialog's list tiles are intentionally
/// avoided — only the stable, meaningful pieces (avatar + source code) are
/// asserted so the check holds across platforms and layout tweaks.
class ChatGroupMessageInfoScenario extends BaseTestScenario {
  ChatGroupMessageInfoScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final (senderMsg, _) = await _prepareTwoMessages(this);

    await robots.messageMenuRobot().openMessageInfo(senderMsg);

    final dialog = $(EventInfoDialog);
    await $.waitUntilVisible(dialog, timeout: const Duration(seconds: 10));
    expect(dialog.$(Avatar), findsWidgets);
    expect(dialog.$(SelectableText), findsWidgets);

    // Close the dialog via its app-bar close button.
    await dialog.$(AppBar).$(IconButton).tap();
    await $.pump();
  }
}
