import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
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

  Future<void> clickOnPenIcon() async{
    await getPenIcon().tap();
    await $.waitUntilVisible($(AppBar).$("New chat"));
  }

  Future<ChatGroupDetailRobot> openChatGroupByIndex(int index) async {
    await (await getListOfChatGroup())[index].root.tap();
    await $.pumpAndSettle();
    return ChatGroupDetailRobot($);
  }

  List<TwakeListItemRobot> getListOfChatGroup() {
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
    final finder = $(TwakeListItem).containing($(ChatListItemTitle).containing($(title)));
    return TwakeListItemRobot($,finder);
  }

  int getUnreadMessage(String title){
    return getChatGroupByTitle(title).getUnreadMessage();
  }
}
