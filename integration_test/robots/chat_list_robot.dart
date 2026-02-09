import 'package:fluffychat/pages/chat_list/chat_list_bottom_navigator.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/pages/search/search_view.dart';
import 'package:fluffychat/pages/chat_list/slidable_chat_list_item.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import 'package:patrol/patrol.dart';
import 'chat_group_detail_robot.dart';
import 'home_robot.dart';
import 'twake_list_item_robot.dart';

class ChatListRobot extends HomeRobot {
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

  Future<void> clickOnPenIcon() async {
    await getPenIcon().tap();
    await cancelSynchronizeContact();
    await $.waitUntilVisible($(AppBar).$("New chat"));
  }

  Future<void> clickOnPinIcon() async {
    await getPinIcon().tap();
    await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getPinIcon());
  }

  Future<void> clickOnUnPinIcon() async {
    await getUnPinIcon().tap();
    await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getUnPinIcon());
  }

  Future<ChatGroupDetailRobot> openChatGroupByIndex(int index) async {
    await (await getListOfChatGroup())[index].root.tap();
    await $.pumpAndSettle();
    return ChatGroupDetailRobot($);
  }

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

  int getUnreadMessage(String title) {
    return getChatGroupByTitle(title).getUnreadMessage();
  }

  Future<void> openSearchScreen() async {
    // Tap on the search TextField in the chat list to open search screen
    await $(TextField).tap();
    await $.pumpAndSettle();
    // Verify SearchView is opened
    await $.waitUntilVisible($(SearchView));

    await confirmShareContactInformation();
    await confirmAccessContact();
  }

  Future<void> openSearchScreenWithoutAcceptPermission() async {
    // Tap on the search TextField in the chat list to open search screen
    await $(TextField).tap();
    // Verify SearchView is opened
    await $.waitUntilVisible($(SearchView));
  }

  Future<int> getChatRoomCounts() async {
    final listChat = await getListOfChatGroup();
    return listChat.length;
  }
}
