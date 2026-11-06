import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:twake_chat/pages/chat/chat_input_row_send_btn.dart';
import 'package:twake_chat/pages/chat/events/message_content.dart';
import 'package:twake_chat/pages/chat/input_bar/input_bar.dart';
import 'package:twake_chat/pages/chat/thread/thread_app_bar_title.dart';
import 'package:twake_chat/pages/chat/thread/thread_summary_card.dart';

import '../base/core_robot.dart';
import 'chat_group_detail_robot.dart';

/// Threads on mobile (spec 2026-11-06, P1): the card under a root, the
/// "Start a thread" menu item and the full-screen thread.
///
/// Labels are the English strings of the spec; the suite runs in English.
class ThreadRobot extends CoreRobot {
  ThreadRobot(super.$);

  static const _timeout = Duration(seconds: 30);

  PatrolFinder _message(String text) => $(
    MessageContent,
  ).containing(find.textContaining(text, findRichText: true));

  /// The card is found by the text of its last reply, so the check does not
  /// depend on where the card sits in the message row.
  PatrolFinder card({required String lastReplyText}) => $(
    ThreadSummaryCard,
  ).containing(find.textContaining(lastReplyText, findRichText: true));

  PatrolFinder get threadHeader => $(ThreadAppBarTitle);

  PatrolFinder get _startThreadItem =>
      $(PullDownMenuItem).containing(find.text('Start a thread'));

  Future<void> expectCard({
    required String lastReplyText,
    required int messageCount,
  }) async {
    final found = card(lastReplyText: lastReplyText);
    await $.waitUntilVisible(found, timeout: _timeout);
    expect(
      found.$(find.textContaining('$messageCount message', findRichText: true)),
      findsOneWidget,
      reason: 'The card must show "$messageCount messages"',
    );
  }

  Future<void> expectNoCard() async {
    await $.pump(const Duration(seconds: 2));
    expect($(ThreadSummaryCard), findsNothing);
  }

  Future<void> openFromCard({required String lastReplyText}) async {
    final found = card(lastReplyText: lastReplyText);
    await $.waitUntilVisible(found, timeout: _timeout);
    await found.tap();
    await $.pumpAndTrySettle();
    await $.waitUntilVisible(threadHeader, timeout: _timeout);
  }

  Future<void> startThreadFrom(String message) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    await $.waitUntilVisible(_startThreadItem);
    await _startThreadItem.tap();
    await $.pumpAndTrySettle();
    await $.waitUntilVisible(threadHeader, timeout: _timeout);
  }

  Future<void> expectNoStartThreadItemOn(String message) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    expect(
      _startThreadItem,
      findsNothing,
      reason: 'A message that already has a thread offers nothing for it',
    );
    await ChatGroupDetailRobot($).closePullDownMenu();
  }

  Future<void> expectThreadScreenOn(String rootText) async {
    await $.waitUntilVisible(threadHeader, timeout: _timeout);
    expect(threadHeader.$(find.text('Thread')), findsOneWidget);
    expect(
      threadHeader.$(find.textContaining(rootText)),
      findsOneWidget,
      reason: 'The header subtitle is the root text',
    );
    expect(
      find.text('Reply in thread'),
      findsOneWidget,
      reason: 'The composer hint of a thread is "Reply in thread"',
    );
  }

  Future<void> expectMessageInThread(String text) async {
    await $.waitUntilVisible(_message(text), timeout: _timeout);
  }

  /// The composer has the focus, so the keyboard is up.
  bool get composerHasFocus {
    final editable = $(InputBar).$(EditableText);
    if (!editable.exists) return false;
    return $.tester.widget<EditableText>(editable.first).focusNode.hasFocus;
  }

  Future<void> sendInThread(String text) async {
    final field = $(InputBar).$(TextField);
    await field.tap();
    await typeSlowlyWithPatrol($, field, text);
    await $.waitUntilVisible($(ChatInputRowSendBtn));
    await $(ChatInputRowSendBtn).tap();
    await $.pump(const Duration(milliseconds: 300));
  }

  /// Leaves the thread with the back arrow of its header.
  Future<void> closeThread() async {
    await goBack();
    await waitUntilAbsent($, threadHeader, timeout: _timeout);
  }

  Future<void> expectNotInMainTimeline(String text) async {
    await $.pump(const Duration(seconds: 2));
    expect(
      _message(text),
      findsNothing,
      reason: 'A thread reply must not show in the main timeline',
    );
  }

  Future<void> openFromUnreadBanner() async {
    final banner = $(find.text('New replies in a thread'));
    await $.waitUntilVisible(banner, timeout: _timeout);
    await $(find.text('Open')).tap();
    await $.pumpAndTrySettle();
    await $.waitUntilVisible(threadHeader, timeout: _timeout);
  }
}
