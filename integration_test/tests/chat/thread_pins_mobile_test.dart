import '../../base/test_base.dart';
import '../../scenarios/thread_pins_scenarios.dart';

/// Threads P4, pins (docs/plan/2026-11-06-threads-mobile-spec.md, THR-M-10;
/// web D345, D438). Nightly only.
void main() {
  TestBase().runPatrolTest(
    tags: ['thread_pins_mobile_test01'],
    description:
        'A pinned thread reply shows in the pins of the room and opens its '
        'thread on it, without moving the room',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => PinnedThreadReplyScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_pins_mobile_test02'],
    description:
        'The thread screen has its own pinned bar, updated when pinning and '
        'unpinning from it',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ThreadPinnedBarScenario($, robots),
  );
}
