import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings.dart';

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';
import '../robots/activity_robot.dart';
import '../robots/home_robot.dart';
import '../robots/thread_robot.dart';
import 'thread_scenarios.dart';

/// Patrol scenarios of the Activity tab, threads P3
/// (docs/plan/2026-11-06-threads-mobile-spec.md, THR-M-12). Nightly only.
///
/// The receiver account plays « the web »: it posts through the
/// Client-Server API.

/// The chat list, the room opened from search closed.
Future<void> _backToChatList(BaseTestScenario scenario) async {
  await scenario.robots.chatGroupDetailRobot().clickOnBackIcon();
  await scenario.robots.searchRobot().backToPreviousScreen();
  await scenario.$(ChatList).waitUntilVisible();
}

/// THR-M-12: the bar is Contacts · Chats · Activity · Settings and each tab
/// still opens its own page (the pages are indexed by their place in the
/// bar: adding Activity must not shift Settings).
class ActivityTabsScenario extends BaseTestScenario {
  ActivityTabsScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await $(ChatList).waitUntilVisible();
    final bar = $.tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar).last,
    );
    expect(bar.items.map((item) => item.label), [
      'Contacts',
      'Chats',
      'Activity',
      'Settings',
    ]);

    final activity = ActivityRobot($);
    await activity.open();
    await activity.expectOnActivityTab();

    await robots.homeRobot().gotoSettingScreen();
    await $(Settings).waitUntilVisible();

    await HomeRobot($).gotoChatListScreen();
    await $(ChatList).waitUntilVisible();

    await robots.homeRobot().gotoContactListScreen();
    await $(ContactsTab).waitUntilVisible();
  }
}

/// THR-M-12: a thread the user follows (they replied in it) is in
/// « Replies »; opening it from there, then going back, lands on the
/// Activity tab, « Replies » still chosen.
class ActivityOpenFollowedThreadScenario extends BaseTestScenario {
  ActivityOpenFollowedThreadScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await openMobileGroupFixture(this);
    final threads = ThreadRobot($);
    final activity = ActivityRobot($);
    final uid = threadUid();
    final root = ThreadText('activity root $uid');
    final webReply = ThreadText('activity web reply $uid');
    final myReply = ThreadText('activity my reply $uid');

    await receiverThread(roomId: fixture.roomId, root: root, reply: webReply);
    await waitForThreadMessage(this, root);
    // Replying makes the user follow the thread.
    await threads.openFromCard(lastReply: webReply);
    await threads.sendInThread(myReply);
    await threads.expectMessageInThread(myReply);
    await threads.closeThread();
    await _backToChatList(this);

    await activity.open();
    await activity.selectFilter('Replies');
    await activity.expectItem(myReply.text);

    await activity.openItem(myReply.text);
    await threads.expectThreadScreenOn(root);

    await threads.closeThread();
    await activity.expectOnActivityTab();
    expect(
      activity.isFilterSelected('Replies'),
      isTrue,
      reason: 'back from the thread, the same filter is chosen',
    );
    await activity.expectItem(myReply.text);
  }
}

/// THR-M-12: a room with a new message is in « Unread »; opening it from
/// there, then going back, lands on the Activity tab, « Unread » still
/// chosen, and the room, now read, has left it.
class ActivityOpenUnreadRoomScenario extends BaseTestScenario {
  ActivityOpenUnreadRoomScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await prepareMobileGroupFixture(this);
    final activity = ActivityRobot($);
    final message = 'activity unread ${threadUid()}';

    await $(ChatList).waitUntilVisible();
    await sendEventAsReceiver(
      roomId: fixture.roomId,
      eventType: EventTypes.Message,
      content: threadText(message),
    );

    await activity.open();
    await activity.selectFilter('Unread');
    await activity.expectItem(message);

    await activity.openItem(message);
    await robots.chatGroupDetailRobot().clickOnBackIcon();

    await activity.expectOnActivityTab();
    expect(
      activity.isFilterSelected('Unread'),
      isTrue,
      reason: 'back from the room, the same filter is chosen',
    );
    await activity.expectNoItem(message);
  }
}
