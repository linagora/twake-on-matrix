import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import 'package:patrol/patrol.dart';
import 'dart:developer';
import '../base/core_robot.dart';
import 'chat_group_detail_robot.dart';

class ChatListRobot extends CoreRobot {
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

  Future<void> enterSearchText(String searchText) async {
    await $(TextField).at(0).waitUntilVisible();
    await $(TextField).at(0).tap();

    final nextButton = Selector(text: 'Next');
    try {
      await $.native.waitUntilVisible(nextButton, timeout: const Duration(seconds: 3));
      await $.native.tap(nextButton);
      await grantNotificationPermission();
    } catch (e) {
      log('Next button not found: $e');
    }
    await $(TextField).enterText(searchText);

    await waitForEitherVisible($: $, first: showLessLabel(),second: noResultLabel(), timeout: const Duration(seconds: 30));
    // await Future.delayed(const Duration(seconds: 2)); 
    await $.pumpAndSettle();
  }

  Future<List<PatrolFinder>> getListOfChatGroup() async {
    final List<PatrolFinder> chatItems = [];

    // Evaluate once to find how many TwakeInkWell widgets exist
    final matches = $(TwakeListItem).evaluate();

    for (int i = 0; i < matches.length; i++) {
      final item = $(TwakeListItem).at(i);
      chatItems.add(item);
    }
    return chatItems;
  }

  Future<void> openChatGroupByIndex(int index) async {
    await (await getListOfChatGroup())[index].tap();
    await $.pumpAndSettle();
  }

  Future<ChatGroupDetailRobot> openChatGroupByTitle(String groupTitle) async {
    await $(ChatListBodyView).tap();
    return ChatGroupDetailRobot($);
  }

}
