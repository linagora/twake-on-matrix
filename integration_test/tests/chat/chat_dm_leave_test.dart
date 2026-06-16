import '../../base/test_base.dart';
import '../../scenarios/chat_dm_leave_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Leave DM chat - Create DM, send message, verify chat list, leave, verify removal',
    // Mobile-only: drives concrete mobile robots and DM-specific UI flows.
    mobileOnly: true,
    scenarioBuilder: ($, robots) => ChatDmLeaveScenario($, robots),
  );
}
