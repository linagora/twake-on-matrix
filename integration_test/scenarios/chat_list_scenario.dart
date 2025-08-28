import 'dart:developer';
import 'package:flutter_test/flutter_test.dart';
import '../base/base_scenario.dart';
import '../robots/chat_list_robot.dart';
import 'package:flutter/material.dart';

class ChatListScenario extends BaseScenario {
  ChatListScenario(super.$);

  Future<void> verifySearchResultViewIsShown() async {
    expect(
        ChatListRobot($).showLessLabel().visible ||
            ChatListRobot($).noResultLabel().visible,
        isTrue,);
    await Future.delayed(const Duration(seconds: 5));
  }

  Future<void> verifySearchResultContains(String keyword) async {
    final items = await ChatListRobot($).getListOfChatGroup();
    final length = items.length;
    var i = 0;

    for (final item in items) {
      i = i + 1;
      final richTextFinder = item.$(RichText);
      final richTextElements = richTextFinder.evaluate();

      if (richTextElements.isEmpty) {
        throw Exception("❌ No RichText found in item $i of $length");
      }
    }
    log("✅ All visible chat groups contain '$keyword'");
  }

  @override
  Future<void> execute() {
    // TODO: implement execute
    throw UnimplementedError();
  }
}
