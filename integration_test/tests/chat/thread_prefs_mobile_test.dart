import '../../base/test_base.dart';
import '../../scenarios/thread_prefs_scenarios.dart';

/// Threads P2 « Suivre, muet, résolu »
/// (docs/plan/2026-11-06-threads-mobile-spec.md). Nightly only.
void main() {
  TestBase().runPatrolTest(
    tags: ['thread_prefs_mobile_test01'],
    description:
        'Follow then unfollow a thread from its menu: the web reads the '
        'choice, the menu follows it',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => FollowFromMenuScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_prefs_mobile_test02'],
    description:
        'Mute a thread: the server holds the silent push rule; unmute '
        'removes it',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => MuteFromMenuScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_prefs_mobile_test03'],
    description:
        'Resolve a thread: check on its header and its card; reopen it',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ResolveFromMenuScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['thread_prefs_mobile_test04'],
    description:
        'A mute and a resolve made on the web apply on the mobile, the '
        'thread still open',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => WebChoiceAppliesScenario($, robots),
  );
}
