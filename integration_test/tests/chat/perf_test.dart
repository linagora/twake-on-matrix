import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../base/core_robot.dart';
import '../../base/perf_collector.dart';
import '../../base/test_base.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../robots/home_robot.dart';

// Room names are injected via --dart-define-from-file.
// Use short ASCII strings to avoid emoji/pipe parsing issues.
//
// Required defines:
//   ScrollRoom1   – image-heavy room for scroll scenarios
//   ScrollRoom2   – second image-heavy room
//   NavRoom       – any room used for navigation cycle warmup/measure

const _scrollRoom1 = String.fromEnvironment(
  'ScrollRoom1',
  defaultValue: 'Bug Me Harder',
);
const _scrollRoom2 = String.fromEnvironment(
  'ScrollRoom2',
  defaultValue: 'tech-radar',
);
const _navRoom = String.fromEnvironment(
  'NavRoom',
  defaultValue: 'Bug Me Harder',
);

void main() {
  TestBase().runPatrolTest(
    description: 'Performance: navigation cycles, scroll, chat list',
    test: ($) async {
      await _warmup($);

      // navPerf is flushed last — collected first but held in memory so the
      // logger has fully settled after the heavier scroll scenarios.
      final navPerf = await _runNavCycles($);

      await _runScrollScenario($, _scrollRoom1, 'scroll_room1', 'room1');
      await _runScrollScenario($, _scrollRoom2, 'scroll_room2', 'room2');
      await _runChatListScroll($);

      await navPerf.flush();
    },
  );
}

/// 3 round-trips without measuring. The Dart JIT needs several cycles to
/// stabilize — 1 cycle is not enough.
Future<void> _warmup(PatrolIntegrationTester $) async {
  await HomeRobot($).gotoChatListScreen();
  await $.pumpAndSettle();
  for (int w = 0; w < 3; w++) {
    await _openRoomFromList($, _navRoom);
    await Future.delayed(const Duration(seconds: 2));
    await ChatGroupDetailRobot($).clickOnBackIcon();
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));
  }
  await Future.delayed(const Duration(seconds: 3));
}

/// Scenario 1 — 5 round-trips chat list → room → back.
/// RSS should plateau after the second cycle; a rising curve signals a leak.
/// Returns the collector unflushed so the caller controls flush ordering.
Future<PerfCollector> _runNavCycles(PatrolIntegrationTester $) async {
  final perf = PerfCollector('nav_cycles');
  perf.start();

  await HomeRobot($).gotoChatListScreen();
  await $.pumpAndSettle();
  perf.checkpoint('chat_list_baseline');

  for (int i = 1; i <= 5; i++) {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    await _openRoomFromList($, _navRoom);
    perf.checkpoint(
      'room_enter_cycle$i',
      extra: {'transition_ms': DateTime.now().millisecondsSinceEpoch - t0},
    );
    await ChatGroupDetailRobot($).clickOnBackIcon();
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));
    perf.checkpoint('chat_list_after_cycle$i');
  }

  perf.stop();
  return perf;
}

/// Scenario 2 & 3 — 30 s of upward scroll in an image-heavy room.
/// Measures cache growth and frame quality under sustained rendering load.
Future<void> _runScrollScenario(
  PatrolIntegrationTester $,
  String roomName,
  String scenario,
  String roomLabel,
) async {
  final perf = PerfCollector(scenario);
  perf.start();

  await HomeRobot($).gotoChatListScreen();
  await $.pumpAndSettle();
  await _openRoomFromList($, roomName);
  perf.checkpoint('room_entered');

  await _scrollForDuration($, perf, roomLabel, durationSeconds: 30);
  perf.checkpoint('scroll_end');

  await Future.delayed(const Duration(seconds: 3));
  perf.checkpoint('scroll_settled');

  await ChatGroupDetailRobot($).clickOnBackIcon();
  await $.pumpAndSettle();
  await Future.delayed(const Duration(seconds: 3));
  perf.checkpoint('back_to_list');

  perf.stop();
  await perf.flush();
}

/// Scenario 4 — chat list scroll.
/// Stresses avatar/thumbnail rendering, unread badges and list item recycling.
Future<void> _runChatListScroll(PatrolIntegrationTester $) async {
  final perf = PerfCollector('chat_list_scroll');
  perf.start();

  await HomeRobot($).gotoChatListScreen();
  await $.pumpAndSettle();
  perf.checkpoint('list_top');

  await CoreRobot($).scrollToBottom($);
  perf.checkpoint('list_bottom');

  await CoreRobot($).scrollToTop($);
  await Future.delayed(const Duration(seconds: 2));
  perf.checkpoint('list_top_again');

  perf.stop();
  await perf.flush();
}

/// Opens a room by scrolling the chat list until a title containing
/// [titleSubstring] is visible, then tapping it.
Future<void> _openRoomFromList(
  PatrolIntegrationTester $,
  String titleSubstring,
) async {
  final target = find.textContaining(titleSubstring);
  await CoreRobot($).scrollUntilVisible($, target);
  await $.tester.tap(target.first);
  await $.pumpAndSettle();
}

/// Scrolls upward (toward older messages) for [durationSeconds] seconds,
/// logging a checkpoint every [logEveryNSteps] drag gestures.
Future<void> _scrollForDuration(
  PatrolIntegrationTester $,
  PerfCollector perf,
  String roomLabel, {
  int durationSeconds = 30,
  int pauseMs = 2000,
  int logEveryNSteps = 5,
}) async {
  final scrollable = find.byType(ChatEventList);
  final steps = (durationSeconds * 1000 / pauseMs).round();

  for (int i = 0; i < steps; i++) {
    // Positive y → finger moves down → content scrolls up → older messages.
    await $.tester.drag(scrollable, const Offset(0, 300));
    await $.pump(Duration(milliseconds: pauseMs));

    if ((i + 1) % logEveryNSteps == 0) {
      perf.checkpoint('${roomLabel}_scroll_step_${i + 1}of$steps');
    }
  }
}
