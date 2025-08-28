import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:flutter_test/flutter_test.dart';
import '../base/test_base.dart';
import '../robots/chat_group_detail_robot.dart';
import '../robots/chat_list_robot.dart';
import '../scenarios/chat_list_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Search for chat group after login',
    test: ($) async {
      await TestBase().loginAndRun($, (_) async {
        const searchPharse = 'thhoang stg change';
        await ChatListRobot($).enterSearchText(searchPharse);
        //verifyAll group are list contains searchPharse
        await ChatListScenario($).verifySearchResultViewIsShown();
        await ChatListScenario($).verifySearchResultContains(searchPharse);
      });
    },
  );

  TestBase().runPatrolTest(
    description: 'Open a chat group',
    test: ($) async {
      await TestBase().loginAndRun($, (_) async {
        await ChatListRobot($).openChatGroupByIndex(5);
        //verify chat group is opened
        expect($(ChatEventList).exists, isTrue);
      });
    },
  );
}
