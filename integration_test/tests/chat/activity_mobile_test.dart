import '../../base/test_base.dart';
import '../../scenarios/activity_scenarios.dart';

/// Threads P3, the Activity tab (docs/plan/2026-11-06-threads-mobile-spec.md,
/// THR-M-12). Nightly only.
void main() {
  TestBase().runPatrolTest(
    tags: ['activity_mobile_test01'],
    description:
        'The bar is Contacts, Chats, Activity, Settings and every tab opens '
        'its own page',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ActivityTabsScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['activity_mobile_test02'],
    description:
        'A followed thread opened from Activity › Replies goes back to '
        'Activity, Replies still chosen',
    mobileOnly: true,
    scenarioBuilder: ($, robots) =>
        ActivityOpenFollowedThreadScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['activity_mobile_test03'],
    description:
        'An unread room opened from Activity › Unread goes back to Activity, '
        'Unread still chosen, the room read',
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ActivityOpenUnreadRoomScenario($, robots),
  );
}
