import '../../base/test_base.dart';
import '../../scenarios/chat_dm_leave_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description:
        'Leave DM chat - Create DM, send message, verify chat list, leave, verify removal',
    // Mobile-only: drives concrete mobile robots and DM-specific UI flows.
    mobileOnly: true,
    // Relies on the staging homeserver creating a DM for a throwaway MXID;
    // the local Synapse rejects the non-existent account, so the chat never
    // appears. Covered on staging by the FTL workflow.
    requiresBackend: true,
    scenarioBuilder: ($, robots) => ChatDmLeaveScenario($, robots),
  );
}
