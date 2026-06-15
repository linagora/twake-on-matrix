import '../base/base_test_scenario.dart';

// ── Configurable via --dart-define ───────────────────────────────────────────

const _sourceRoom = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'My Default Group',
);

// Non-overlapping names: a textContaining finder on "Receiver Group" would also
// match "Receiver Group 2", so neither name is a prefix of the other.
const _receiver1 = String.fromEnvironment(
  'ForwardReceiver1Name',
  defaultValue: 'Receiver Alpha',
);

const _receiver2 = String.fromEnvironment(
  'ForwardReceiver2Name',
  defaultValue: 'Receiver Beta',
);

int _uid() => DateTime.now().microsecondsSinceEpoch;

/// Opens [_sourceRoom], sends a unique message, waits for it to appear, then
/// opens the message action menu and triggers Forward — leaving `ForwardView`
/// on screen. Returns the sent message text.
///
/// Drives the UI exclusively through the abstract robots; the menu-opening
/// gesture (mobile long-press vs web hover) lives in the message-menu robot.
Future<String> _sendAndOpenForward(BaseTestScenario scenario) async {
  final robots = scenario.robots;
  final $ = scenario.$;

  await robots.chatListRobot().openSearchScreen();
  final opened = await robots.searchViewRobot().searchAndOpenRoom(_sourceRoom);
  if (!opened) {
    throw Exception('Test failed: Room "$_sourceRoom" was not found.');
  }
  // Extra settle time so the chat view and composer are fully ready.
  await $.pump(const Duration(seconds: 1));

  final msg = 'fwd-test at ${_uid()}';
  await robots.chatGroupDetailRobot().sendMessage(msg);
  final finder = await robots.chatGroupDetailRobot().getText(msg);
  await $.waitUntilVisible(finder, timeout: const Duration(seconds: 30));

  await robots.messageMenuRobot().openForward(msg);
  return msg;
}

/// Forward a message to a single recipient.
///
/// After a single forward the controller pops the Forward screen then routes
/// to the receiver's chat — the test asserts that room is opened.
class ForwardSingleRecipientScenario extends BaseTestScenario {
  ForwardSingleRecipientScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await _sendAndOpenForward(this);

    final forward = robots.forwardRobot();
    await forward.searchRoom(_receiver1);
    await forward.verifyRoomInList(_receiver1);
    forward.verifyRoomNotSelected(_receiver1);

    await forward.selectChatByName(_receiver1);
    forward.verifyRoomSelected(_receiver1);

    await forward.tapSendButton();
    await forward.verifyOpenedRoom(_receiver1);
  }
}

/// Forward a message to multiple recipients.
///
/// After a multi forward the controller pops back to the source chat and shows
/// a success snackbar; the Forward screen is dismissed.
class ForwardMultiRecipientScenario extends BaseTestScenario {
  ForwardMultiRecipientScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await _sendAndOpenForward(this);

    final forward = robots.forwardRobot();

    // Search and select the first receiver.
    await forward.searchRoom(_receiver1);
    await forward.verifyRoomInList(_receiver1);
    forward.verifyRoomNotSelected(_receiver1);
    await forward.selectChatByName(_receiver1);
    forward.verifyRoomSelected(_receiver1);

    // Clear search, then search and select the second receiver.
    await forward.clearSearch();
    await forward.searchRoom(_receiver2);
    await forward.verifyRoomInList(_receiver2);
    forward.verifyRoomNotSelected(_receiver2);
    await forward.selectChatByName(_receiver2);
    forward.verifyRoomSelected(_receiver2);

    // NOTE: _receiver1 is filtered out by the current search query so it is no
    // longer in the rendered list — its selection state persists in the
    // controller, and the send button being enabled confirms both are queued.
    await forward.tapSendButton();

    // Multi-forward pops back to the source chat and dismisses the Forward view.
    await forward.verifyForwardViewDismissed();
    await forward.verifyMultiForwardSuccessSnackbar(2);
  }
}
