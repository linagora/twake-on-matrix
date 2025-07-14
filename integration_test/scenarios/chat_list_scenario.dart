import 'package:flutter_test/flutter_test.dart';
import '../base/base_scenario.dart';
import '../robots/chat_list_robot.dart';

import 'package:flutter/material.dart';

class ChatListScenario extends BaseScenario {
  ChatListScenario(super.$);

  Future<void> verifyGroupsContain(String keyword) async {
    final items = await ChatListRobot($).getListOfChatGroup();

    for (final item in items) {
      final matches = item.evaluate(); // returns Iterable<Element>
      bool found = false;

      for (final el in matches) {
        final widget = el.widget;

        if (widget is Text) {
          final value = widget.data ?? '';
          if (value.toLowerCase().contains(keyword.toLowerCase())) {
            found = true;
            break;
          }
        }
      }

      if (!found) {
        throw Exception("❌ Group does not contain '$keyword'");
      }
    }

    print("✅ All visible chat groups contain '$keyword'");
  }
  
  @override
  Future<void> execute() {
    // TODO: implement execute
    throw UnimplementedError();
  }
}
