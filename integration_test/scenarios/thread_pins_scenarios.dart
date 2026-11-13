import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/pages/chat/chat_pinned_events/pinned_events_view.dart';
import 'package:twake_chat/pages/chat/chat_pinned_events/pinned_messages_screen.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';
import 'package:twake_chat/pages/chat/thread/thread_summary_card.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../base/core_robot.dart';
import '../base/mobile_group_fixture.dart';
import '../robots/chat_group_detail_robot.dart';
import '../robots/menu_robot.dart';
import '../robots/thread_robot.dart';
import 'thread_scenarios.dart';

/// Patrol scenarios of threads P4, pins
/// (docs/plan/2026-11-06-threads-mobile-spec.md, THR-M-10; web D345, D438).
/// Nightly only: written, not run locally.

const _timeout = Duration(seconds: 30);

/// The pinned bar on screen: the room one on the room screen, the thread one
/// on the thread screen (the room screen under it is offstage, not found).
class _PinnedBar extends CoreRobot {
  _PinnedBar(super.$);

  PatrolFinder get bar => $(PinnedEventsView);

  PatrolFinder showing(ThreadText message) =>
      bar.$(find.textContaining(message.text, findRichText: true));

  Future<void> expectShowing(ThreadText message) =>
      $.waitUntilVisible(showing(message), timeout: _timeout);

  Future<void> expectHidden() => waitUntilAbsent(
    $,
    bar.$(find.byTooltip('Pinned messages')),
    timeout: _timeout,
  );

  Future<void> tapOn(ThreadText message) async {
    await expectShowing(message);
    await showing(message).tap();
    await $.pumpAndTrySettle();
  }

  Future<void> openList() async {
    await bar.$(TwakeIconButton).first.tap();
    await $.waitUntilVisible($(PinnedMessagesScreen), timeout: _timeout);
  }
}

Future<void> _pin(PatrolIntegrationTester $, ThreadText message) async {
  await ChatGroupDetailRobot($).openPullDownMenu(message.text);
  await PullDownMenuRobot($).getPinItem().tap();
  await $.pumpAndTrySettle();
}

Future<void> _unpin(PatrolIntegrationTester $, ThreadText message) async {
  await ChatGroupDetailRobot($).openPullDownMenu(message.text);
  await PullDownMenuRobot($).getUnpinItem().tap();
  await $.pumpAndTrySettle();
}

/// ThreadRobot.expectNotInMainTimeline, where the pinned bar may also show
/// the reply: its text may be on the card of its root or in the bar only.
Future<void> _expectNotInMainTimeline(
  PatrolIntegrationTester $,
  ThreadText reply,
) async {
  await $.pump(const Duration(seconds: 2));
  final text = find.textContaining(reply.text, findRichText: true);
  Set<Element> inside(Type type) =>
      find.descendant(of: find.byType(type), matching: text).evaluate().toSet();
  final elsewhere = text
      .evaluate()
      .toSet()
      .difference(inside(ThreadSummaryCard))
      .difference(inside(PinnedEventsView));
  expect(
    elsewhere,
    isEmpty,
    reason: 'A pinned thread reply must not show in the main timeline',
  );
}

/// The message of [text] on screen is the one highlighted (the soft tint of
/// a jump, `highlightedEventIdNotifier`).
void _expectHighlighted(
  PatrolIntegrationTester $,
  String eventId,
  String text,
) {
  final message = $(
    Message,
  ).containing(find.textContaining(text, findRichText: true));
  expect(message, findsWidgets);
  expect(
    $.tester.widget<Message>(message.first).highlightedEventIdNotifier?.value,
    eventId,
    reason: 'The pinned reply is highlighted in its thread',
  );
}

/// THR-M-10, D345: a reply pinned in a thread shows in the pinned bar and
/// list of the room; tapping it opens its thread, scrolled to the reply and
/// highlighted, and the conversation of the room does not move.
class PinnedThreadReplyScenario extends BaseTestScenario {
  PinnedThreadReplyScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await openMobileGroupFixture(this);
    final threads = ThreadRobot($);
    final pins = _PinnedBar($);
    final uid = threadUid();
    final root = ThreadText('pinned-thread root $uid');
    final reply = ThreadText('pinned reply $uid');

    final ids = await receiverThread(
      roomId: fixture.roomId,
      root: root,
      reply: reply,
    );
    await waitForThreadMessage(this, root);

    await threads.openFromCard(lastReply: reply);
    await threads.expectMessageInThread(reply);
    await _pin($, reply);
    await threads.closeThread();

    // The bar of the room shows the pinned reply.
    await pins.expectShowing(reply);
    await _expectNotInMainTimeline($, reply);

    // Tapping it opens the thread on the reply, highlighted.
    await pins.tapOn(reply);
    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(reply);
    _expectHighlighted($, ids.replyId, reply.text);

    // Back in the room: the conversation is where it was, on the root.
    await threads.closeThread();
    await waitForThreadMessage(this, root);
    await _expectNotInMainTimeline($, reply);

    // The list of the pinned messages of the room shows it too, and « Jump
    // to message » opens its thread.
    await pins.openList();
    final listed = $(
      PinnedMessagesScreen,
    ).$(find.textContaining(reply.text, findRichText: true));
    await $.waitUntilVisible(listed, timeout: _timeout);
    await listed.longPress();
    await $.pumpAndTrySettle();
    await $(find.text('Jump to message')).tap();
    await $.pumpAndTrySettle();
    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(reply);
    _expectHighlighted($, ids.replyId, reply.text);
  }
}

/// D438: the thread screen shows, under its header, a bar with the pins of
/// that thread only (root and replies), hidden while it has none; a tap
/// jumps within the thread; pinning and unpinning from the thread screen
/// update the bar of the thread and the bar of the room. The bar of the
/// room is not shown on the thread screen.
class ThreadPinnedBarScenario extends BaseTestScenario {
  ThreadPinnedBarScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await openMobileGroupFixture(this);
    final threads = ThreadRobot($);
    final pins = _PinnedBar($);
    final uid = threadUid();
    final root = ThreadText('pin-bar root $uid');
    final reply = ThreadText('pin-bar reply $uid');
    final roomMessage = ThreadText('pin-bar room message $uid');

    await receiverThread(roomId: fixture.roomId, root: root, reply: reply);
    await sendEventAsReceiver(
      roomId: fixture.roomId,
      eventType: EventTypes.Message,
      content: threadText(roomMessage.text),
    );
    await waitForThreadMessage(this, roomMessage);

    // A pin of the room only: the thread shows no bar, nor the room's.
    await _pin($, roomMessage);
    await pins.expectShowing(roomMessage);
    await threads.openFromCard(lastReply: reply);
    await threads.expectMessageInThread(reply);
    await pins.expectHidden();
    expect(pins.showing(roomMessage), findsNothing);

    // Pinning from the thread screen: the bar of the thread shows the pin.
    await _pin($, reply);
    await pins.expectShowing(reply);
    expect(pins.showing(roomMessage), findsNothing);
    await _pin($, root);

    // Each tap jumps within the thread to the pin shown, then shows the
    // other one; the thread screen stays open. Which one comes first is the
    // order of the bar of the room, not checked here.
    final first = pins.showing(root).exists ? root : reply;
    final second = first == root ? reply : root;
    await pins.tapOn(first);
    await threads.expectThreadScreenOn(root);
    await pins.expectShowing(second);
    await pins.tapOn(second);
    await threads.expectThreadScreenOn(root);
    await pins.expectShowing(first);
    expect(pins.showing(roomMessage), findsNothing);

    // The pins of the room have the new pins too.
    await threads.closeThread();
    await pins.openList();
    await $.waitUntilVisible(
      $(
        PinnedMessagesScreen,
      ).$(find.textContaining(reply.text, findRichText: true)),
      timeout: _timeout,
    );
    await ChatGroupDetailRobot($).clickOnBackIcon();

    // Unpinning from the thread screen: the bar of the thread goes when its
    // last pin goes; the room keeps its own pin.
    await threads.openFromCard(lastReply: reply);
    await _unpin($, reply);
    await _unpin($, root);
    await pins.expectHidden();
    await threads.closeThread();
    await pins.expectShowing(roomMessage);
    await pins.openList();
    final listedReply = $(
      PinnedMessagesScreen,
    ).$(find.textContaining(reply.text, findRichText: true));
    await pins.waitUntilAbsent($, listedReply, timeout: _timeout);
  }
}
