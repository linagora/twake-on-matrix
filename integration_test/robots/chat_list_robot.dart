import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import 'package:patrol/patrol.dart';
import 'chat_group_detail_robot.dart';
import 'home_robot.dart';
import 'twake_list_item_robot.dart';

class ChatListRobot extends HomeRobot {
  ChatListRobot(super.$);
  
   Future<bool> isVisible() async {
    final chatListSelector = $(ChatList);
    try {
      await chatListSelector.waitUntilVisible(timeout: const Duration(seconds: 120));
      return true;
    } catch (_) {
      return false;
    }
  }

  PatrolFinder showLessLabel() {
    return $("Show Less");
  }

  PatrolFinder noResultLabel() {
    return $("No Results");
  }

  Future<void> openChatGroupByIndex(int index) async {
    await (await getListOfChatGroup())[index].root.tap();
    await $.pumpAndSettle();
  }

  Future<ChatGroupDetailRobot> openChatGroupByTitle(String groupTitle) async {
    await $(ChatListBodyView).tap();
    return ChatGroupDetailRobot($);
  }

  Future<List<TwakeListItemRobot>> getListOfChatGroup() async {
    final List<TwakeListItemRobot> groupList = [];

    // Evaluate once to find how many TwakeInkWell widgets exist
    final matches = $(TwakeListItem).evaluate();

    for (int i = 0; i < matches.length; i++) {
      final item = $(TwakeListItem).at(i);
      groupList.add(TwakeListItemRobot($,item));
    }
    return groupList;
  }

}
