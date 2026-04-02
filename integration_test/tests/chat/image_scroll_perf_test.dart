import 'dart:io' show ProcessInfo;

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
/// Flushing at the end ensures idevicesyslog is reliably capturing output.
final _pendingMetrics = <String>[];

/// Records imageCache + process memory state at [label] for later flush.
void _logCache(String label) {
  final cache = PaintingBinding.instance.imageCache;
  final rss = ProcessInfo.currentRss;
  _pendingMetrics.add(
    'PERF_METRIC | $label'
    ' | bytes=${cache.currentSizeBytes}'
    ' | count=${cache.currentSize}'
    ' | live=${cache.liveImageCount}'
    ' | pending=${cache.pendingImageCount}'
    ' | rss=$rss',
  );
}

/// Prints all accumulated metrics with 200ms spacing so the OS logger keeps up.
Future<void> _flushMetrics() async {
  for (final line in _pendingMetrics) {
    // ignore: avoid_print
    print(line);
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

/// Scrolls upward (toward older, image-heavy messages) for approximately
/// [durationSeconds] by performing repeated drag gestures with [pauseMs]
/// settle time between each.
///
/// Logs cache state every [logEveryNSteps] steps so we can observe the
/// memory growth curve across the scroll session.
Future<void> _scrollForDuration(
  PatrolIntegrationTester $,
  Finder scrollable,
  String roomLabel, {
  int durationSeconds = 30,
  int pauseMs = 2000,
  int logEveryNSteps = 5,
}) async {
  final steps = (durationSeconds * 1000 / pauseMs).round();
  for (int i = 0; i < steps; i++) {
    // Positive y → finger moves down → content scrolls up → older messages
    await $.tester.drag(scrollable, const Offset(0, 300));
    await $.pump(Duration(milliseconds: pauseMs));
    if ((i + 1) % logEveryNSteps == 0) {
      _logCache('${roomLabel}_scroll_step_${i + 1}of$steps');
    }
  }
}

void main() {
  // Search terms are intentionally short/ASCII to avoid emoji/pipe parsing
  // issues with --dart-define-from-file. The search does a prefix match so
  // "Bug Me Harder" finds "Bug Me Harder 😏  | Twake" and "tech-radar" is exact.
  const room1Search = String.fromEnvironment(
    'ScrollRoom1',
    defaultValue: 'Bug Me Harder',
  );
  const room2Search = String.fromEnvironment(
    'ScrollRoom2',
    defaultValue: 'tech-radar',
  );

  TestBase().runPatrolTest(
    description:
        'Measure imageCache memory during 30s scroll in two image-heavy rooms',
    test: ($) async {
      final scrollable = find.byType(ChatEventList);

      // ── 0. Chat list baseline ─────────────────────────────────────────────
      await HomeRobot($).gotoChatListScreen();
      await $.pumpAndSettle();
      _logCache('initial_lobby');

      // ── 1. Room 1: bug me harder ──────────────────────────────────────────
      // Use openChatGroupByTitle (no confirmAccessMedia) to avoid accidentally
      // tapping "Go to Settings" on a previously-denied iOS permission.
      await ChatScenario($).openChatGroupByTitle(room1Search);
      await $.pumpAndSettle();
      _logCache('room1_entered');

      await _scrollForDuration($, scrollable, 'room1');
      _logCache('room1_after_30s_scroll');

      await ChatGroupDetailRobot($).clickOnBackIcon();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3));
      _logCache('room1_left');

      // ── 2. Room 2: tech radar ─────────────────────────────────────────────
      await ChatScenario($).openChatGroupByTitle(room2Search);
      await $.pumpAndSettle();
      _logCache('room2_entered');

      await _scrollForDuration($, scrollable, 'room2');
      _logCache('room2_after_30s_scroll');

      await ChatGroupDetailRobot($).clickOnBackIcon();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3));
      _logCache('room2_left');

      // ── 3. Final lobby ────────────────────────────────────────────────────
      await HomeRobot($).gotoChatListScreen();
      await $.pumpAndSettle();
      _logCache('final_lobby');

      // Flush all metrics in one burst at the end.
      await _flushMetrics();
    },
  );
}
