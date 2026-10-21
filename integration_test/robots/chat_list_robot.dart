import 'dart:async';

import 'package:twake_chat/pages/chat/chat_view.dart';
import 'package:twake_chat/pages/chat_draft/draft_chat_view.dart';
import 'package:twake_chat/pages/chat_list/chat_list_bottom_navigator.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_title.dart';
import 'package:twake_chat/pages/search/search_view.dart';
import 'package:twake_chat/pages/chat_list/slidable_chat_list_item.dart';
import 'package:twake_chat/widgets/twake_components/twake_fab.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import 'package:patrol/patrol.dart';
import 'abstract/abstract_chat_list_robot.dart';
import 'add_member_robot.dart';
import 'chat_group_detail_robot.dart';
import 'home_robot.dart';
import 'new_chat_robot.dart';
import 'setting_for_new_group.dart';
import 'twake_list_item_robot.dart';

class ChatListRobot extends HomeRobot implements AbstractChatListRobot {
  ChatListRobot(super.$);

  PatrolFinder showLessLabel() {
    return $("Show Less");
  }

  PatrolFinder noResultLabel() {
    return $("No Results");
  }

  PatrolFinder getPenIcon() {
    return $(TwakeFloatingActionButton);
  }

  PatrolFinder getPinIcon() {
    return $(ChatListBottomNavigator).$(InkWell).containing($("Pin"));
  }

  PatrolFinder getUnPinIcon() {
    return $(ChatListBottomNavigator).$(InkWell).containing($("Unpin"));
  }

  @override
  Future<void> clickOnPenIcon() async {
    await getPenIcon().tap();
    await cancelSynchronizeContact();
    // The new-chat screen's AppBar title ("New chat") is mobile-only — on web's
    // wide layout it is not rendered. Wait instead for the "New Group Chat"
    // entry, which is present on both platforms.
    await $.waitUntilVisible($("New Group Chat"));
  }

  @override
  Future<void> clickOnPinIcon() async {
    await getPinIcon().tap();
    await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getPinIcon());
  }

  @override
  Future<void> clickOnUnPinIcon() async {
    await getUnPinIcon().tap();
    await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getUnPinIcon());
  }

  @override
  Future<ChatGroupDetailRobot> openChatGroupByIndex(int index) async {
    // Search/list population is async; wait for at least one row before
    // indexing to avoid a RangeError or opening the wrong chat in web/headless.
    await $.waitUntilVisible($(TwakeListItem));
    await (await getListOfChatGroup())[index].root.tap();
    await $.pumpAndSettle();
    return ChatGroupDetailRobot($);
  }

  @override
  Future<void> openChatByTitle(String title) async {
    final chat = getChatGroupByTitle(title);
    await scrollUntilVisible($, chat.root);
    await $.waitUntilVisible(chat.root, timeout: const Duration(seconds: 60));
    await chat.root.tap();
    await $.pumpAndSettle();
  }

  @override
  Future<List<TwakeListItemRobot>> getListOfChatGroup() async {
    final List<TwakeListItemRobot> groupList = [];

    // Evaluate once to find how many TwakeListItem widgets exist
    final matches = $(TwakeListItem).evaluate();
    for (final element in matches) {
      final finder = $(element.widget.runtimeType);
      groupList.add(TwakeListItemRobot($, finder));
    }
    return groupList;
  }

  TwakeListItemRobot getChatGroupByTitle(String title) {
    final finder = $(
      SlidableChatListItem,
    ).containing($(ChatListItemTitle).containing($(title)));
    return TwakeListItemRobot($, finder);
  }

  @override
  int getUnreadMessage(String title) {
    return getChatGroupByTitle(title).getUnreadMessage();
  }

  @override
  Future<void> openSearchScreen() async {
    // Tap on the search TextField in the chat list to open search screen
    await $(TextField).tap();
    await $.pumpAndSettle();

    // Handle the contacts permission dialog before waiting for SearchView,
    // as the dialog overlays SearchView and makes it non-hit-testable
    await confirmShareContactInformation();
    await confirmAccessContact();

    // Verify SearchView is opened
    await $.waitUntilVisible($(SearchView));
  }

  Future<void> openSearchScreenWithoutAcceptPermission() async {
    // Tap on the search TextField in the chat list to open search screen
    await $(TextField).tap();
    // Verify SearchView is opened
    await $.pumpAndSettle();
    await $.waitUntilVisible($(SearchView));
  }

  @override
  Future<int> getChatRoomCounts() async {
    final listChat = await getListOfChatGroup();
    return listChat.length;
  }

  @override
  Future<bool> isListScrollable() async {
    // No `root` filter: the chat list's scroll container differs by platform
    // (mobile `SingleChildScrollView`, web a different scrollable), so just
    // assert a scrollable exists on the list screen.
    return isActuallyScrollable($);
  }

  bool _isPinned(TwakeListItemRobot item) => item.getPinIcon().visible;

  /// Favouriting / unfavouriting triggers a room sync; the chat list
  /// StreamBuilder rate-limits rebuilds to 1s. A long-press during that
  /// rebuild is dropped (gesture succeeds in Patrol, but `onLongPress` never
  /// runs), so selection mode never opens. Retry until the checkbox appears.
  Future<void> _enterSelectionMode(TwakeListItemRobot item) async {
    final checkbox = item.getCheckBox();
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (!checkbox.exists && DateTime.now().isBefore(deadline)) {
      await $.tester.ensureVisible(item.root);
      await item.root.longPress();
      await $.pump(const Duration(milliseconds: 700));
    }
    await $.waitUntilVisible(checkbox, timeout: const Duration(seconds: 15));
  }

  Future<void> _waitForPinState(String title, {required bool pinned}) async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      final item = getChatGroupByTitle(title);
      if (item.root.exists && _isPinned(item) == pinned) {
        await $.pumpAndSettle();
        return;
      }
      await $.pump(const Duration(milliseconds: 300));
    }
    throw TimeoutException(
      'Chat "$title" did not reach pinned=$pinned within 20s',
    );
  }

  @override
  Future<void> pinChat(String title) async {
    final item = getChatGroupByTitle(title);
    await scrollUntilVisible($, item.root);
    if (!_isPinned(item)) {
      await _enterSelectionMode(item);
      await clickOnPinIcon();
      // Let the post-favourite list rebuild finish before the next long-press.
      await _waitForPinState(title, pinned: true);
    }
  }

  @override
  Future<void> unpinChat(String title) async {
    final item = getChatGroupByTitle(title);
    await scrollUntilVisible($, item.root);
    if (_isPinned(item)) {
      await _enterSelectionMode(item);
      await clickOnUnPinIcon();
      await _waitForPinState(title, pinned: false);
    }
  }

  @override
  Future<bool> isChatPinned(String title) async {
    final item = getChatGroupByTitle(title);
    await scrollUntilVisible($, item.root);
    return _isPinned(item);
  }

  @override
  Future<bool> createDirectMessage(String account) async {
    await clickOnPenIcon();
    await NewChatRobot($).makeASearch(account);
    final accounts = NewChatRobot($).getListOfAccount();
    if (accounts.isEmpty) return false;
    await accounts[0].root.tap();
    await waitForEitherVisible(
      $: $,
      first: $(ChatView),
      second: $(DraftChatView),
      timeout: const Duration(seconds: 30),
    );
    return true;
  }

  @override
  Future<void> createGroupChat(String name, String memberSearchKey) async {
    await clickOnPenIcon();
    await NewChatRobot($).clickOnNewGroupChatIcon();
    await AddMemberRobot($).makeASearch(memberSearchKey);
    await AddMemberRobot($).selectAllFilteredAccounts();
    await AddMemberRobot($).clickOnNextIcon();
    await SettingForNewGroupRobot($).settingForNewGroup(name);
    await SettingForNewGroupRobot($).getConfirmIcon().tap();
    await $.pump(const Duration(seconds: 10));
    await $.waitUntilVisible($(ChatView));
  }
}
