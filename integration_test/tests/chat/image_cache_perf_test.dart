import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../base/test_base.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../robots/home_robot.dart';
import '../../scenarios/chat_scenario.dart';

/// Accumulated metrics flushed at the end of the test.
/// This ensures they're all printed in one burst near test completion,
/// when idevicesyslog is reliably capturing Flutter app output.
final _pendingMetrics = <String>[];

/// Records imageCache state at [label] for later flush.
void _logCache(String label) {
  final cache = PaintingBinding.instance.imageCache;
  _pendingMetrics.add(
    'PERF_METRIC | $label | bytes=${cache.currentSizeBytes} | count=${cache.currentSize}',
  );
}

/// Prints all accumulated metrics, one per 200ms so the OS logger can keep up.
Future<void> _flushMetrics() async {
  for (final line in _pendingMetrics) {
    // ignore: avoid_print
    print(line);
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

/// Scrolls the chat list upward (toward older messages / more images)
/// by performing [steps] drag gestures with a [pauseMs] ms settle between each.
Future<void> _scrollAndLoad(
  PatrolIntegrationTester $,
  Finder scrollable, {
  int steps = 10,
  int pauseMs = 2000,
}) async {
  for (int i = 0; i < steps; i++) {
    // Drag upward to reveal older messages (image-heavy history)
    await $.tester.drag(scrollable, const Offset(0, 300));
    await $.pump(Duration(milliseconds: pauseMs));
  }
}

void main() {
  // Room names are configurable via --dart-define.
  // Both default to the same TEST_GROUP so only one env var is required.
  const room1 = String.fromEnvironment(
    'ImageRoom1',
    defaultValue: 'TEST_GROUP',
  );
  const room2 = String.fromEnvironment(
    'ImageRoom2',
    defaultValue: 'TEST_GROUP',
  );

  TestBase().runPatrolTest(
    description: 'Measure imageCache memory across image-heavy room navigation',
    test: ($) async {
      // ── 0. Start at chat list ────────────────────────────────────────────
      await HomeRobot($).gotoChatListScreen();
      await $.pumpAndSettle();
      _logCache('initial_lobby');

      final scrollable = find.byType(ChatEventList);

      // ── 1. Room 1 ────────────────────────────────────────────────────────
      await ChatScenario($).openChatGroup(room1);
      await $.pumpAndSettle();
      _logCache('room1_entered');

      // 10 drags × 2 s settle ≈ 20 s of image loading
      await _scrollAndLoad($, scrollable);
      _logCache('room1_after_scroll');

      await ChatGroupDetailRobot($).clickOnBackIcon();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));
      _logCache('room1_left');

      // ── 2. Room 2 ────────────────────────────────────────────────────────
      await ChatScenario($).openChatGroup(room2);
      await $.pumpAndSettle();
      _logCache('room2_entered');

      await _scrollAndLoad($, scrollable);
      _logCache('room2_after_scroll');

      await ChatGroupDetailRobot($).clickOnBackIcon();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));
      _logCache('room2_left');

      // ── Final lobby ───────────────────────────────────────────────────────
      _logCache('final_lobby');

      // Flush all metrics at the end in one burst so the syslog capture
      // is guaranteed to be running and can keep up.
      await _flushMetrics();
    },
  );
}
