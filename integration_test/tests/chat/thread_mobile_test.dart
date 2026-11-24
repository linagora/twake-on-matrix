import '../../base/test_base.dart';
import '../../scenarios/thread_scenarios.dart';

/// Threads P1 (spec comment on #3589:
/// https://github.com/linagora/twake-on-matrix/pull/3589#issuecomment-6744797534). Nightly only.
void main() {
  TestBase().runPatrolTest(
    tags: ['thread_mobile_test01'],
    description:
        'A thread written on the web shows as a card, opens full screen, '
        'and a mobile reply lands in it',
    scenarioBuilder: ($, robots) => ReceivedThreadScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_mobile_test02'],
    description:
        'Start a thread: root alone with keyboard, nothing created on '
        'leave, first reply creates the card',
    scenarioBuilder: ($, robots) => StartThreadScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_mobile_test03'],
    description: 'A read room with an unread followed thread shows the banner',
    scenarioBuilder: ($, robots) => UnreadThreadBannerScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_mobile_test04'],
    description: 'A matrix.to link to a thread reply opens its thread',
    scenarioBuilder: ($, robots) => ThreadReplyLinkScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_mobile_test05'],
    description: 'A search result that is a thread reply opens its thread',
    scenarioBuilder: ($, robots) => ThreadReplySearchScenario($, robots),
  );
}
