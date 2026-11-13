import '../../base/test_base.dart';
import '../../scenarios/thread_scenarios.dart';

/// Threads P1 (docs/plan/2026-11-06-threads-mobile-spec.md). Nightly only.
void main() {
  TestBase().runPatrolTest(
    tags: ['thread_mobile_test01'],
    description:
        'A thread written on the web shows as a card, opens full screen, '
        'and a mobile reply lands in it',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ReceivedThreadScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_mobile_test02'],
    description:
        'Start a thread: root alone with keyboard, nothing created on '
        'leave, first reply creates the card',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => StartThreadScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_mobile_test03'],
    description: 'A read room with an unread followed thread shows the banner',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => UnreadThreadBannerScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_mobile_test04'],
    description: 'A matrix.to link to a thread reply opens its thread',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ThreadReplyLinkScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_mobile_test05'],
    description: 'A search result that is a thread reply opens its thread',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ThreadReplySearchScenario($, robots),
  );
}
