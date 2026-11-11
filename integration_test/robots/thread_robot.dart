import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:twake_chat/pages/chat/chat_input_row_send_btn.dart';
import 'package:twake_chat/pages/chat/events/message_content.dart';
import 'package:twake_chat/pages/chat/input_bar/input_bar.dart';
import 'package:twake_chat/pages/chat/thread/thread_app_bar_title.dart';
import 'package:twake_chat/pages/chat/thread/thread_resolved_mark.dart';
import 'package:twake_chat/pages/chat/thread/thread_summary_card.dart';

import '../base/core_robot.dart';
import 'chat_group_detail_robot.dart';

/// A message of a thread scenario, the root or a reply, found on screen by
/// its text.
class ThreadText {
  const ThreadText(this.text);

  final String text;

  @override
  String toString() => text;
}

/// Threads on mobile (spec 2026-11-06, P1): the card under a root, the
/// "Start a thread" menu item and the full-screen thread.
///
/// Labels are the English strings of the spec; the suite runs in English.
class ThreadRobot extends CoreRobot {
  ThreadRobot(super.$);

  static const _timeout = Duration(seconds: 30);

  PatrolFinder _message(ThreadText message) => $(
    MessageContent,
  ).containing(find.textContaining(message.text, findRichText: true));

  /// The card is found by the text of its last reply, so the check does not
  /// depend on where the card sits in the message row.
  PatrolFinder card({required ThreadText lastReply}) => $(
    ThreadSummaryCard,
  ).containing(find.textContaining(lastReply.text, findRichText: true));

  PatrolFinder get threadHeader => $(ThreadAppBarTitle);

  /// The header is a Column whose centre lies right of the short "Thread"
  /// line, so the header itself is never hit-testable: wait on the title.
  PatrolFinder get _threadTitle => threadHeader.$(find.text('Thread'));

  PatrolFinder get _startThreadItem =>
      $(PullDownMenuItem).containing(find.text('Start a thread'));

  Future<void> expectCard({
    required ThreadText lastReply,
    required int messageCount,
  }) async {
    final found = card(lastReply: lastReply);
    await $.waitUntilVisible(found, timeout: _timeout);
    expect(
      found.$(find.textContaining('$messageCount message', findRichText: true)),
      findsOneWidget,
      reason: 'The card must show "$messageCount messages"',
    );
  }

  Future<void> openFromCard({required ThreadText lastReply}) async {
    final found = card(lastReply: lastReply);
    await $.waitUntilVisible(found, timeout: _timeout);
    await found.tap();
    await $.pumpAndTrySettle();
    await $.waitUntilVisible(_threadTitle, timeout: _timeout);
  }

  Future<void> startThreadFrom(ThreadText message) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message.text);
    await $.waitUntilVisible(_startThreadItem);
    await _startThreadItem.tap();
    await $.pumpAndTrySettle();
    await $.waitUntilVisible(_threadTitle, timeout: _timeout);
  }

  Future<void> expectNoStartThreadItemOn(ThreadText message) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message.text);
    expect(
      _startThreadItem,
      findsNothing,
      reason: 'A message that already has a thread offers nothing for it',
    );
    await ChatGroupDetailRobot($).closePullDownMenu();
  }

  Future<void> expectThreadScreenOn(ThreadText root) async {
    await $.waitUntilVisible(_threadTitle, timeout: _timeout);
    expect(_threadTitle, findsOneWidget);
    expect(
      threadHeader.$(find.textContaining(root.text)),
      findsOneWidget,
      reason: 'The header subtitle is the root text',
    );
    expect(
      find.text('Reply in thread'),
      findsOneWidget,
      reason: 'The composer hint of a thread is "Reply in thread"',
    );
  }

  Future<void> expectMessageInThread(ThreadText message) async {
    await $.waitUntilVisible(_message(message), timeout: _timeout);
  }

  /// The composer has the focus, so the keyboard is up.
  bool get composerHasFocus {
    final editable = $(InputBar).$(EditableText);
    if (!editable.exists) return false;
    return $.tester.widget<EditableText>(editable.first).focusNode.hasFocus;
  }

  Future<void> sendInThread(ThreadText message) async {
    final field = $(InputBar).$(TextField);
    await field.tap();
    await typeSlowlyWithPatrol($, field, message.text);
    await $.waitUntilVisible($(ChatInputRowSendBtn));
    await $(ChatInputRowSendBtn).tap();
    await $.pump(const Duration(milliseconds: 300));
  }

  /// Leaves the thread with the back arrow of its header.
  ///
  /// Not [goBack]: back in the room, the iOS text cursor of the room composer
  /// (focus given back) blinks for ever, so its strict `pumpAndSettle` never
  /// settles. The header check below is the real wait.
  Future<void> closeThread() async {
    await $(AppBar).$(find.byIcon(Icons.arrow_back_ios)).first.tap();
    await $.pumpAndTrySettle();
    await waitUntilAbsent($, threadHeader, timeout: _timeout);
  }

  /// The reply text may show on the card of its root, nowhere else.
  Future<void> expectNotInMainTimeline(ThreadText reply) async {
    await $.pump(const Duration(seconds: 2));
    final everywhere = find
        .textContaining(reply.text, findRichText: true)
        .evaluate()
        .toSet();
    final onCards = find
        .descendant(
          of: find.byType(ThreadSummaryCard),
          matching: find.textContaining(reply.text, findRichText: true),
        )
        .evaluate()
        .toSet();
    expect(
      everywhere.difference(onCards),
      isEmpty,
      reason: 'A thread reply must not show in the main timeline',
    );
  }

  /// The check « Resolved » (THR-M-08), found by its accessible label.
  Finder get _resolvedMark => find.byType(ResolvedMark);

  PatrolFinder get _threadMenuButton => $(AppBar).$(find.byTooltip('More'));

  /// Opens the « ⋮ » menu of the thread header (THR-M-07, THR-M-08).
  Future<void> openThreadMenu() async {
    await $.waitUntilVisible(_threadMenuButton, timeout: _timeout);
    await _threadMenuButton.tap();
    await $.pumpAndTrySettle();
  }

  Future<void> _closeThreadMenu() async {
    await $.tester.tapAt(Offset.zero);
    await $.pumpAndTrySettle();
  }

  /// Opens the « ⋮ » menu until it offers every item of [items]: the items
  /// are built when the menu opens, and a choice made elsewhere (a sync, the
  /// web) may land a moment later. Fails after [_timeout].
  Future<void> _openThreadMenuOffering(List<String> items) async {
    final deadline = DateTime.now().add(_timeout);
    while (true) {
      await openThreadMenu();
      if (items.every((item) => $(find.text(item)).exists)) return;
      if (DateTime.now().isAfter(deadline)) {
        fail('The thread menu must offer $items');
      }
      await _closeThreadMenu();
      await $.pump(const Duration(seconds: 1));
    }
  }

  /// Chooses [item] of the « ⋮ » menu, by its English label.
  Future<void> chooseInThreadMenu(String item) async {
    await _openThreadMenuOffering([item]);
    await $(find.text(item)).tap();
    await $.pumpAndTrySettle();
  }

  /// The « ⋮ » menu offers every item of [offered], then is closed again.
  Future<void> expectThreadMenuOffers(List<String> offered) async {
    await _openThreadMenuOffering(offered);
    await _closeThreadMenu();
  }

  Future<void> expectResolvedInHeader() async {
    await $.waitUntilExists(threadHeader.$(_resolvedMark), timeout: _timeout);
  }

  Future<void> expectNotResolvedInHeader() async {
    await waitUntilAbsent($, threadHeader.$(_resolvedMark), timeout: _timeout);
  }

  Future<void> expectResolvedOnCard({required ThreadText lastReply}) async {
    await $.waitUntilExists(
      card(lastReply: lastReply).$(_resolvedMark),
      timeout: _timeout,
    );
  }

  Future<void> openFromUnreadBanner() async {
    final banner = $(find.text('New replies in a thread'));
    await $.waitUntilVisible(banner, timeout: _timeout);
    await $(find.text('Open')).tap();
    await $.pumpAndTrySettle();
    await $.waitUntilVisible(_threadTitle, timeout: _timeout);
  }
}
