import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../base/test_base.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../robots/forward_robot.dart';
import '../../robots/home_robot.dart';
import '../../robots/menu_robot.dart';
import '../../scenarios/chat_scenario.dart';

// ── Configurable via --dart-define ───────────────────────────────────────────

const _sourceRoom = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'My Default Group',
);

const _singleReceiver = String.fromEnvironment(
  'ForwardReceiver1Name',
  defaultValue: 'Receiver Group',
);

// ignore: unused_element
const _secondReceiver = String.fromEnvironment(
  'ForwardReceiver2Name',
  defaultValue: 'Receiver Group 2',
);

// ── Helpers ───────────────────────────────────────────────────────────────────

int _uid() => DateTime.now().microsecondsSinceEpoch;

/// Opens [_sourceRoom], sends a unique message, waits for it to appear.
Future<String> _prepareMessage(PatrolIntegrationTester $) async {
  final msg = 'fwd-test at ${_uid()}';
  await HomeRobot($).gotoChatListScreen();
  await ChatScenario($).openChatGroupByTitle(_sourceRoom);
  // Extra settle time so the chat view and keyboard are fully ready.
  await $.pump(const Duration(seconds: 1));
  await ChatScenario($).sendAMesage(msg);
  final finder = await ChatGroupDetailRobot($).getText(msg);
  await $.waitUntilVisible(finder, timeout: const Duration(seconds: 30));
  return msg;
}

/// Long-presses [message], taps "Forward", waits for [ForwardView] to appear.
Future<void> _openForwardScreen(
  PatrolIntegrationTester $,
  String message,
) async {
  await ChatGroupDetailRobot($).openPullDownMenu(message);
  await PullDownMenuRobot($).getForwardItem().tap();

  await $.pump(const Duration(milliseconds: 300));
  await $.pumpAndTrySettle();

  await $.waitUntilExists($(ForwardView), timeout: const Duration(seconds: 15));
  expect($(ForwardView).exists, isTrue, reason: 'ForwardView not found');
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── Test 1: forward to a single recipient ─────────────────────────────────
  //
  // After single forward: ForwardController pops itself then calls
  // RoomRoute(receiverId).go() → app opens the receiver's ChatView.
  TestBase().runPatrolTest(
    tags: ['forward_message_test01'],
    description: 'Forward a message to a single recipient',
    test: ($) async {
      final msg = await _prepareMessage($);

      await _openForwardScreen($, msg);

      final robot = ForwardRobot($);

      await robot.searchRoom(_singleReceiver);
      await robot.verifyRoomInList(_singleReceiver);
      robot.verifyRoomNotSelected(_singleReceiver);

      await robot.selectChatByName(_singleReceiver);
      robot.verifyRoomSelected(_singleReceiver);

      await robot.tapSendButton();

      // App must open the receiver's chat room.
      await $.waitUntilVisible(
        $(ChatView),
        timeout: const Duration(seconds: 15),
      );
      expect(
        $(
          ChatAppBarTitle,
        ).containing(find.textContaining(_singleReceiver)).exists,
        isTrue,
        reason: 'Expected to open "$_singleReceiver" room',
      );
    },
  );

  // ── Test 2: forward to multiple recipients ────────────────────────────────
  //
  // After multi forward: ForwardController calls Navigator.pop() → app returns
  // to the source ChatView and shows a snackbar.
  TestBase().runPatrolTest(
    tags: ['forward_message_test02'],
    description: 'Forward a message to multiple recipients',
    test: ($) async {
      final msg = await _prepareMessage($);

      await _openForwardScreen($, msg);

      final robot = ForwardRobot($);

      // Search and select the first receiver.
      await robot.searchRoom(_singleReceiver);
      await robot.verifyRoomInList(_singleReceiver);
      robot.verifyRoomNotSelected(_singleReceiver);
      await robot.selectChatByName(_singleReceiver);
      robot.verifyRoomSelected(_singleReceiver);

      // Clear search, then search and select the second receiver.
      await robot.clearSearch();
      await robot.searchRoom(_secondReceiver);
      await robot.verifyRoomInList(_secondReceiver);
      robot.verifyRoomNotSelected(_secondReceiver);
      await robot.selectChatByName(_secondReceiver);
      robot.verifyRoomSelected(_secondReceiver);

      // NOTE: _singleReceiver is filtered out by the current search query so
      // it is not in the rendered list – we cannot check its checkbox here.
      // Selection state persists in the controller; the send button being
      // enabled (2 rooms selected) confirms both are queued.

      await robot.tapSendButton();

      // Multi-forward pops back to the previous screen (source ChatView).
      await $.waitUntilVisible(
        $(ChatView),
        timeout: const Duration(seconds: 15),
      );
      // ForwardView must no longer be present.
      expect(
        $(ForwardView).exists,
        isFalse,
        reason: 'ForwardView should be dismissed',
      );
    },
  );
}
