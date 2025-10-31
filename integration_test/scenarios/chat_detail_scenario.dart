import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import '../base/base_scenario.dart';
import '../robots/chat_group_detail_robot.dart';
import 'package:flutter/material.dart';

class ChatDetailScenario extends BaseScenario {
  ChatDetailScenario(super.$);

  Future<void> makeASearch(String searchText) async {
    await ChatGroupDetailRobot($).getSearchIcon().tap();
    await $.waitUntilVisible($(AppBar).$(TextField));
    await $(AppBar).$(TextField).enterText(searchText);
    // await SearchRobot($).enterSearchText(searchText);
    await ChatGroupDetailRobot($).waitForEitherVisible($: $, first: $(TwakeListItem), second: $("No Results"), timeout: const Duration(seconds: 10));
    await Future.delayed(const Duration(seconds: 2));
  }

}
