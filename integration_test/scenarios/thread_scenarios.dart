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
/// (docs/plan/2026-11-06-threads-mobile-spec.md, THR-M-01 to 06 and 11).
///
/// The receiver account plays "the web": it posts roots and thread replies
/// through the Client-Server API with the same relation the web writes.

int _uid() => DateTime.now().microsecondsSinceEpoch;

Client _client(BaseTestScenario scenario) => twake.Matrix.of(
  scenario.$.tester.element(find.byType(Scaffold).first),
).client;

Map<String, Object?> _text(String body) => {'msgtype': 'm.text', 'body': body};

Map<String, Object?> _threadReply({
  required String rootId,
  required String lastId,
  required String body,
}) => {
  'msgtype': 'm.text',
  'body': body,
  'm.relates_to': {
    'rel_type': RelationshipTypes.thread,
    'event_id': rootId,
    'is_falling_back': true,
    'm.in_reply_to': {'event_id': lastId},
  },
};

/// Posts a root and one thread reply as the receiver; returns their ids.
Future<({String rootId, String replyId})> _receiverThread({
  required String roomId,
  required ThreadText root,
  required ThreadText reply,
}) async {
  final rootId = await sendEventAsReceiver(
    roomId: roomId,
    eventType: EventTypes.Message,
    content: _text(root.text),
  );
  final replyId = await sendEventAsReceiver(
    roomId: roomId,
    eventType: EventTypes.Message,
    content: _threadReply(rootId: rootId, lastId: rootId, body: reply.text),
  );
  return (rootId: rootId, replyId: replyId);
}

Future<void> _waitForMessage(BaseTestScenario scenario, ThreadText text) async {
  final message = await ChatGroupDetailRobot(scenario.$).getText(text.text);
  await scenario.$.waitUntilVisible(
    message,
    timeout: const Duration(seconds: 30),
  );
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
    final uid = _uid();
    final root = ThreadText('thread-root $uid');
    final webReply = ThreadText('web reply $uid');
    final mobileReply = ThreadText('mobile reply $uid');

    final ids = await _receiverThread(
      roomId: fixture.roomId,
      root: root,
      reply: webReply,
    );

    await _waitForMessage(this, root);
    await threads.expectCard(lastReply: webReply, messageCount: 1);
    await threads.expectNotInMainTimeline(webReply);

    await threads.openFromCard(lastReply: webReply);
    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(root);
    await threads.expectMessageInThread(webReply);
    expect(
      threads.composerHasFocus,
      isFalse,
      reason: 'Opening an existing thread does not open the keyboard',
    );

    await threads.sendInThread(mobileReply);
    await threads.expectMessageInThread(mobileReply);

    await threads.closeThread();
    await _waitForMessage(this, root);
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
    final uid = _uid();
    final root = ThreadText('start-thread root $uid');
    final firstReply = ThreadText('first reply $uid');

    await chat.sendMessage(root.text);
    await _waitForMessage(this, root);

    await threads.startThreadFrom(root);
    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(root);
    expect(
      threads.composerHasFocus,
      isTrue,
      reason: '"Start a thread" opens the keyboard',
    );

    await threads.closeThread();
    await _waitForMessage(this, root);
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
    final uid = _uid();
    final root = ThreadText('banner root $uid');
    final myReply = ThreadText('my banner reply $uid');
    final laterReply = ThreadText('later web reply $uid');

    final rootId = await sendEventAsReceiver(
      roomId: fixture.roomId,
      eventType: EventTypes.Message,
      content: _text(root.text),
    );
    await _waitForMessage(this, root);

    // Replying makes the user follow the thread (P1: participation).
    await threads.startThreadFrom(root);
    await threads.sendInThread(myReply);
    await threads.expectMessageInThread(myReply);
    await threads.closeThread();
    await chat.clickOnBackIcon();
    // The room was opened from search: leave search to reach the chat list.
    await robots.searchRobot().backToPreviousScreen();
    await $(ChatList).waitUntilVisible();

    await sendEventAsReceiver(
      roomId: fixture.roomId,
      eventType: EventTypes.Message,
      content: _threadReply(
        rootId: rootId,
        lastId: rootId,
        body: laterReply.text,
      ),
    );
    await $.pump(const Duration(seconds: 5));

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
    final uid = _uid();
    final root = ThreadText('link root $uid');
    final reply = ThreadText('linked reply $uid');

    final ids = await _receiverThread(
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
      content: _text(link.text),
    );
    await _waitForMessage(this, link);

    await ChatGroupDetailRobot($).tapTextInMessage(link.text);
    await $.pumpAndTrySettle();

    await threads.expectThreadScreenOn(root);
    await threads.expectMessageInThread(reply);

    await threads.closeThread();
    await _waitForMessage(this, link);
  }
}

/// THR-M-11: a search result that is a thread reply opens its thread.
class ThreadReplySearchScenario extends BaseTestScenario {
  ThreadReplySearchScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await openMobileGroupFixture(this);
    final threads = ThreadRobot($);
    final uid = _uid();
    final root = ThreadText('search root $uid');
    final reply = ThreadText('searchable reply $uid');

    await _receiverThread(roomId: fixture.roomId, root: root, reply: reply);
    await _waitForMessage(this, root);

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
