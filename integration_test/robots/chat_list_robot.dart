import 'package:fluffychat/pages/chat_list/chat_list_bottom_navigator.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/pages/chat_list/slidable_chat_list_item.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Future<PatrolFinder> getNumberOfSelectedChatLable() async{
    await $.waitUntilVisible($(ChatListHeader).$(Text));
    return $(ChatListHeader).$(Text);
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

  Future<void> clickOnPinIcon() async {
    await getPinIcon().tap();
    await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getPinIcon());
  }

  Future<void> clickOnUnPinIcon() async {
    await getUnPinIcon().tap();
    await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getUnPinIcon());
  }

  Future<void> clickOnReadIcon() async {
    await getMarkAsReadIcon().tap();
    await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getMarkAsReadIcon());
  }

  Future<void> clickOnUnreadIcon() async {
    await getMarkAsUnReadIcon().tap();
    await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getMarkAsUnReadIcon());
  }

  Future<void> clickOnMuteIcon() async {
      await getMuteIcon().tap();
      await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getMuteIcon());
    }

  Future<void> clickOnUnMuteIcon() async {
      await getUnmuteIcon().tap();
      await ChatListRobot($).waitUntilAbsent($, ChatListRobot($).getUnmuteIcon());
  }

  Future<void> clickOnPenIcon() async{
    await getPenIcon().tap();
    await $.waitUntilVisible($(AppBar).$("New chat"));
  }

  Future<ChatGroupDetailRobot> openChatGroupByIndex(int index) async {
    await ( getListOfChatGroup())[index].root.tap();
    await $.pumpAndSettle();
    return ChatGroupDetailRobot($);
  }

  List<TwakeListItemRobot> getListOfChatGroup() {
    final count = $(SlidableChatListItem).evaluate().length;
    return List.generate(count, (i) => TwakeListItemRobot($, $(SlidableChatListItem).at(i)));
  }

  TwakeListItemRobot getChatGroupByTitle(String title){
    final finder = $(SlidableChatListItem).containing($(ChatListItemTitle).containing($(title))).first;
    return TwakeListItemRobot($,finder);
  }

  int getUnreadMessage(String title){
    return getChatGroupByTitle(title).getUnreadMessage();
  }
}
