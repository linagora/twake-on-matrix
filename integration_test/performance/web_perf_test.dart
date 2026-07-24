import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../base/base_test_scenario.dart';
import '../base/test_base.dart';
import '../base/web_perf_collector.dart';
import '../robots/chat_group_detail_robot.dart';
import '../robots/home_robot.dart';

const _roomTitle = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'TEST_GROUP',
);
const _repetitions = 3;

void main() {
  TestBase().runPatrolTest(
    description: 'Web performance: navigation and continuous room scroll',
    webOnly: true,
    scenarioBuilder: ($, robots) => WebPerfScenario($, robots),
  );
}

/// Runs deterministic browser interactions after a short cache warm-up.
class WebPerfScenario extends BaseTestScenario {
  WebPerfScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await _warmUp($);
    for (var repetition = 0; repetition < _repetitions; repetition++) {
      await _measureNavigation($);
      await _measureRoomScroll($);
      await ChatGroupDetailRobot($).clickOnBackIcon();
      await $.pumpAndTrySettle();
    }
  }
}

Future<void> _warmUp(PatrolIntegrationTester $) async {
  for (var iteration = 0; iteration < 2; iteration++) {
    final chatList = await HomeRobot($).gotoChatListScreen();
    await chatList.openChatByTitle(_roomTitle);
    await ChatGroupDetailRobot($).clickOnBackIcon();
    await $.pumpAndTrySettle();
  }
}

Future<void> _measureNavigation(PatrolIntegrationTester $) async {
  final chatList = await HomeRobot($).gotoChatListScreen();
  final collector = WebPerfCollector('web_navigation');
  final stopwatch = Stopwatch()..start();
  collector.start();

  await chatList.openChatByTitle(_roomTitle);
  stopwatch.stop();
  collector.stop();
  collector.checkpoint(
    'room_opened',
    extra: {'transition_ms': stopwatch.elapsedMicroseconds / 1000},
  );
  await collector.flush($.log);
}

Future<void> _measureRoomScroll(PatrolIntegrationTester $) async {
  final collector = WebPerfCollector('web_room_scroll');
  final scrollable = find.byType(ChatEventList);
  collector.start();

  for (var step = 0; step < 60; step++) {
    final direction = step < 30 ? 180.0 : -180.0;
    await $.tester.drag(scrollable, Offset(0, direction));
    await $.pump(const Duration(milliseconds: 80));
  }

  collector.stop();
  collector.checkpoint('scroll_completed');
  await collector.flush($.log);
}
