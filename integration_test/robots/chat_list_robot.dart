import 'package:fluffychat/pages/chat_list/chat_list_bottom_navigator.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
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
   
  PatrolFinder getPenIcon(){
    return $(TwakeFloatingActionButton);
  }

  PatrolFinder getPinIcon(){
    return $(ChatListBottomNavigator).$(InkWell).containing($("Pin"));
  }

  PatrolFinder getUnPinIcon(){
    return $(ChatListBottomNavigator).$(InkWell).containing($("Unpin"));
  }

  PatrolFinder getMarkAsReadIcon(){
    return $(ChatListBottomNavigator).$(InkWell).containing($("Read"));
  }

  PatrolFinder getMarkAsUnReadIcon(){
    return $(ChatListBottomNavigator).$(InkWell).containing($("Unread"));
  }

  PatrolFinder getMuteIcon(){
    return $(ChatListBottomNavigator).$(InkWell).containing($("Mute"));
  }

  PatrolFinder getUnmuteIcon(){
    return $(ChatListBottomNavigator).$(InkWell).containing($("Unmute"));
  }

  Future<void> clickOnPenIcon() async{
    await getPenIcon().tap();
    await $.waitUntilVisible($(AppBar).$("New chat"));
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

  TwakeListItemRobot getChatGroupByTitle(String title){
    final finder = $(SlidableChatListItem).containing($(ChatListItemTitle).containing($(title)));
    return TwakeListItemRobot($,finder);
  }

  int getUnreadMessage(String title){
    return getChatGroupByTitle(title).getUnreadMessage();
  }
}
