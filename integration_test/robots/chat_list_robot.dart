import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_inkwell.dart';
import 'package:patrol/patrol.dart';
import 'dart:developer';

import '../base/core_robot.dart';
import 'chat_group_detail_robot.dart';

class ChatListRobot extends CoreRobot {
  ChatListRobot(super.$);
  
   Future<bool> isVisible() async {
    final chatListSelector = $(ChatList);
    try {
      await chatListSelector.waitUntilVisible(timeout: const Duration(seconds: 10));
      return true;
    } catch (_) {
      return false;
    }
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

    final showLessVisible = $(const Text('Show Less')).visible;
    final noResultsVisible = $(const Text('No Results')).visible;

    expect(
      showLessVisible || noResultsVisible,
      isTrue,
      reason: 'Expected either "Show Less" or "No Results" to be visible',
    );
  }

  Future<List<PatrolFinder>> getListOfChatGroup() async {
   final List<PatrolFinder> chatItems = [];

    // Evaluate once to find how many TwakeInkWell widgets exist
    final matches = $(TwakeInkWell).evaluate();

    for (int i = 0; i < matches.length; i++) {
      final item = $(TwakeInkWell).at(i);
      chatItems.add(item);
    }
    return chatItems;
  }

  Future<void> openChatGroupByIndex(int index) async {
    await (await getListOfChatGroup())[index].tap();
  }

  Future<ChatGroupDetailRobot> openChatGroupByTitle(String groupTitle) async {
    await $(ChatListBodyView).tap();
    return ChatGroupDetailRobot($);
  }

}
