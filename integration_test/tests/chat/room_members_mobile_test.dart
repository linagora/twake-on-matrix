import '../../base/test_base.dart';
import '../../scenarios/room_members_scenarios.dart';

void main() {
  TestBase().runPatrolTest(
    tags: ['room_members_mobile_test01'],
    description: 'Promote a member to admin from Group info',
    scenarioBuilder: ($, robots) => PromoteMemberToAdminScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['room_members_mobile_test02'],
    description: 'Select two members and remove them together',
    scenarioBuilder: ($, robots) => RemoveSelectedMembersScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['room_members_mobile_test03'],
    description: 'Unban a removed member from Removed Users',
    scenarioBuilder: ($, robots) => UnbanFromRemovedUsersScenario($, robots),
  );
}
