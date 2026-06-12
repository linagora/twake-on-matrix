import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';

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
  final finder = await scenario.robots.chatGroupDetailRobot().getText(message);
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
