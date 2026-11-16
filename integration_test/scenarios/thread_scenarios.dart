import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_search/chat_search_view.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';
import '../robots/chat_group_detail_robot.dart';
import '../robots/thread_robot.dart';

/// Patrol scenarios of threads, P1 "Lire et répondre"
/// (spec comment on #3589, THR-M-01 to 06 and 11:
/// https://github.com/linagora/twake-on-matrix/pull/3589#issuecomment-6744797534,
/// THR-M-06 update: ...#issuecomment-6793337834).
///
/// The receiver account plays "the web": it posts roots and thread replies
/// through the Client-Server API with the same relation the web writes.

/// A suffix that keeps the messages of one run apart from the others.
int threadUid() => DateTime.now().microsecondsSinceEpoch;

Client _client(BaseTestScenario scenario) => twake.Matrix.of(
  scenario.$.tester.element(find.byType(Scaffold).first),
).client;

/// The content of a plain text message.
Map<String, Object?> threadText(ThreadText message) => {
  'msgtype': 'm.text',
  'body': message.text,
};

/// A reply to [rootId], which is also the last event of the thread.
Map<String, Object?> _threadReply(String rootId, ThreadText reply) => {
  'msgtype': 'm.text',
  'body': reply.text,
  'm.relates_to': {
    'rel_type': RelationshipTypes.thread,
    'event_id': rootId,
    'is_falling_back': true,
    'm.in_reply_to': {'event_id': rootId},
  },
};

/// Posts a root and one thread reply as the receiver; returns their ids.
Future<({String rootId, String replyId})> receiverThread({
  required String roomId,
  required ThreadText root,
  required ThreadText reply,
}) async {
  final rootId = await sendEventAsReceiver(
    roomId: roomId,
    eventType: EventTypes.Message,
    content: threadText(root),
  );
  final replyId = await sendEventAsReceiver(
    roomId: roomId,
    eventType: EventTypes.Message,
    content: _threadReply(rootId, reply),
  );
  return (rootId: rootId, replyId: replyId);
}

/// Waits until [text] shows on screen.
Future<void> waitForThreadMessage(
  BaseTestScenario scenario,
  ThreadText text,
) async {
  final message = await ChatGroupDetailRobot(scenario.$).getText(text.text);
  await scenario.$.waitUntilVisible(
    message,
    timeout: const Duration(seconds: 30),
  );
}

/// Polls until [check] holds, pumping between tries; fails after [timeout].
Future<void> _waitUntil(
  BaseTestScenario scenario,
  bool Function() check, {
  required String reason,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!check()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out: $reason');
    await scenario.$.pump(const Duration(milliseconds: 250));
  }
}

/// Waits until the client has synced [eventId] of [roomId].
Future<void> _waitForSyncedEvent(
  BaseTestScenario scenario,
  ({String roomId, String eventId}) sent,
) async {
  final (:roomId, :eventId) = sent;
  final room = _client(scenario).getRoomById(roomId)!;
  final timeline = await room.getTimeline();
  try {
    await _waitUntil(
      scenario,
      () => timeline.events.any((e) => e.eventId == eventId),
      reason: 'event $eventId was not synced',
    );
  } finally {
    timeline.cancelSubscriptions();
  }
}

/// THR-M-01, 02, 04, 05: a thread written on the web shows as a card under
/// its root, not in the main timeline; the card opens the thread full
/// screen; a reply from the mobile lands in the same thread.
class ReceivedThreadScenario extends BaseTestScenario {
  ReceivedThreadScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await openMobileGroupFixture(this);
    final threads = ThreadRobot($);
    final uid = threadUid();
    final root = ThreadText('thread-root $uid');
    final webReply = ThreadText('web reply $uid');
    final mobileReply = ThreadText('mobile reply $uid');

    final ids = await receiverThread(
      roomId: fixture.roomId,
      root: root,
      reply: webReply,
    );

    await waitForThreadMessage(this, root);
    await threads.expectCard(lastReply: webReply, messageCount: 1);
    await threads.expectNotInMainTimeline(webReply);

    await threads.openFromCard(lastReply: webReply);
    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(root);
    await threads.expectMessageInThread(webReply);
    // Focus is requested once the thread has loaded: give it time to arrive.
    await $.pump(const Duration(seconds: 2));
    expect(
      threads.composerHasFocus,
      isFalse,
      reason: 'Opening an existing thread does not open the keyboard',
    );

    await threads.sendInThread(mobileReply);
    await threads.expectMessageInThread(mobileReply);

    await threads.closeThread();
    await waitForThreadMessage(this, root);
    await threads.expectCard(lastReply: mobileReply, messageCount: 2);
    await threads.expectNotInMainTimeline(mobileReply);

    // What the web reads: the mobile reply is a thread relation of the root.
    final relations = await _client(this).getRelatingEventsWithRelType(
      fixture.roomId,
      ids.rootId,
      RelationshipTypes.thread,
    );
    final mobileEvent = relations.chunk.firstWhere(
      (event) => event.content['body'] == mobileReply.text,
    );
    final relatesTo = mobileEvent.content['m.relates_to'] as Map;
    expect(relatesTo['rel_type'], RelationshipTypes.thread);
    expect(relatesTo['event_id'], ids.rootId);
    expect(
      mobileEvent.content['body'],
      mobileReply.text,
      reason: 'No quote fallback is prepended to a thread reply',
    );
  }
}

/// THR-M-03: "Start a thread" opens the thread on the root alone with the
/// keyboard up; leaving without sending creates nothing; the first reply
/// creates the thread and its card; the menu then offers nothing for it.
class StartThreadScenario extends BaseTestScenario {
  StartThreadScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await openMobileGroupFixture(this);
    final chat = ChatGroupDetailRobot($);
    final threads = ThreadRobot($);
    final uid = threadUid();
    final root = ThreadText('start-thread root $uid');
    final firstReply = ThreadText('first reply $uid');

    await chat.sendMessage(root.text);
    await waitForThreadMessage(this, root);

    await threads.startThreadFrom(root);
    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(root);
    await _waitUntil(
      this,
      () => threads.composerHasFocus,
      reason: '"Start a thread" opens the keyboard',
      timeout: const Duration(seconds: 5),
    );

    await threads.closeThread();
    await waitForThreadMessage(this, root);
    final room = _client(this).getRoomById(fixture.roomId)!;
    expect(
      room.lastEvent?.body,
      root.text,
      reason: 'Leaving an empty new thread sends no event',
    );

    await threads.startThreadFrom(root);
    await threads.sendInThread(firstReply);
    await threads.expectMessageInThread(firstReply);
    await threads.closeThread();

    await threads.expectCard(lastReply: firstReply, messageCount: 1);
    await threads.expectNotInMainTimeline(firstReply);
    await threads.expectNoStartThreadItemOn(root);
  }
}

/// THR-M-06: a room whose only unread content is a followed thread shows
/// "New replies in a thread"; "Open" opens that thread.
class UnreadThreadBannerScenario extends BaseTestScenario {
  UnreadThreadBannerScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await openMobileGroupFixture(this);
    final chat = ChatGroupDetailRobot($);
    final threads = ThreadRobot($);
    final uid = threadUid();
    final root = ThreadText('banner root $uid');
    final myReply = ThreadText('my banner reply $uid');
    final laterReply = ThreadText('later web reply $uid');

    final rootId = await sendEventAsReceiver(
      roomId: fixture.roomId,
      eventType: EventTypes.Message,
      content: threadText(root),
    );
    await waitForThreadMessage(this, root);

    // Replying makes the user follow the thread (P1: participation).
    await threads.startThreadFrom(root);
    await threads.sendInThread(myReply);
    await threads.expectMessageInThread(myReply);
    await threads.closeThread();
    await chat.clickOnBackIcon();
    // The room was opened from search: leave search to reach the chat list.
    await robots.searchRobot().backToPreviousScreen();
    await $(ChatList).waitUntilVisible();

    final laterReplyId = await sendEventAsReceiver(
      roomId: fixture.roomId,
      eventType: EventTypes.Message,
      content: _threadReply(rootId, laterReply),
    );
    await _waitForSyncedEvent(this, (
      roomId: fixture.roomId,
      eventId: laterReplyId,
    ));

    // Reopen from the chat list, as a user would: a second search open can
    // hang on the iOS contacts dialog that Patrol cannot answer.
    await robots.chatListRobot().openChatByTitle(fixture.title);
    await threads.openFromUnreadBanner();
    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(laterReply);
  }
}

/// THR-M-11: a matrix.to link to a thread reply opens its thread, with the
/// room under it in the stack.
class ThreadReplyLinkScenario extends BaseTestScenario {
  ThreadReplyLinkScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await openMobileGroupFixture(this);
    final threads = ThreadRobot($);
    final uid = threadUid();
    final root = ThreadText('link root $uid');
    final reply = ThreadText('linked reply $uid');

    final ids = await receiverThread(
      roomId: fixture.roomId,
      root: root,
      reply: reply,
    );
    final link = ThreadText(
      'https://matrix.to/#/${Uri.encodeComponent(fixture.roomId)}/'
      '${Uri.encodeComponent(ids.replyId)}',
    );
    await sendEventAsReceiver(
      roomId: fixture.roomId,
      eventType: EventTypes.Message,
      content: threadText(link),
    );
    await waitForThreadMessage(this, link);

    await ChatGroupDetailRobot($).tapTextInMessage(link.text);
    await $.pumpAndTrySettle();

    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(reply);

    await threads.closeThread();
    await waitForThreadMessage(this, link);
  }
}

/// THR-M-11: a search result that is a thread reply opens its thread.
class ThreadReplySearchScenario extends BaseTestScenario {
  ThreadReplySearchScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await openMobileGroupFixture(this);
    final threads = ThreadRobot($);
    final uid = threadUid();
    final root = ThreadText('search root $uid');
    final reply = ThreadText('searchable reply $uid');

    await receiverThread(roomId: fixture.roomId, root: root, reply: reply);
    await waitForThreadMessage(this, root);

    await ChatGroupDetailRobot($).getSearchIcon().first.tap();
    final searchView = $(ChatSearchView);
    await $.waitUntilVisible(searchView);
    await threads.typeSlowlyWithPatrol(
      $,
      searchView.$(TextField),
      'searchable reply $uid',
    );

    final result = searchView
        .$(InkWell)
        .containing(find.textContaining(reply.text, findRichText: true));
    await $.waitUntilVisible(result, timeout: const Duration(seconds: 30));
    await result.first.tap();
    await $.pumpAndTrySettle();

    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(reply);
  }
}
