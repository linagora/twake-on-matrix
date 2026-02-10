import 'package:flutter_test/flutter_test.dart';

import '../../base/test_base.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../robots/chat_list_robot.dart';
import '../../robots/home_robot.dart';
import '../../scenarios/chat_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Should not create any chat '
        'when create direct chat with unsupported matrix user',
    test: ($) async {
      const searchPhrase = '@awsd:awsd.com';
      await HomeRobot($).gotoChatListScreen();
      final beforeChatRoomCounts = await ChatListRobot($).getChatRoomCounts();
      await ChatScenario($).enterSearchText(searchPhrase);
      await ChatListRobot($).openChatGroupByIndex(0);
      // send a message
      await ChatScenario($).sendAMesage('hello');

      // check message is sent
      await ChatGroupDetailRobot(
        $,
      ).expectSnackShown($, timeout: const Duration(seconds: 30));
      await ChatScenario(
        $,
      ).backToChatLisFromChatGroupScreen(isOpenGroupFromSearchResult: true);

      final afterChatRoomCounts = await ChatListRobot($).getChatRoomCounts();
      expect(afterChatRoomCounts, beforeChatRoomCounts);
    },
  );
}
