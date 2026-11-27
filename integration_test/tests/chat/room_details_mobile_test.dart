import '../../base/test_base.dart';
import '../../scenarios/room_details_scenarios.dart';

void main() {
  TestBase().runPatrolTest(
    tags: ['room_details_mobile_test01'],
    description: 'Edit the group name and description from Group info',
    scenarioBuilder: ($, robots) => RoomDetailsEditInfoScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['room_details_mobile_test02'],
    description: 'Invite a member from Group info, then remove them',
    scenarioBuilder: ($, robots) =>
        RoomMembersInviteAndRemoveScenario($, robots),
  );

  TestBase().runPatrolTest(
    tags: ['room_details_mobile_test03'],
    description: 'Mute and unmute the group from Group info',
    scenarioBuilder: ($, robots) => RoomDetailsMuteScenario($, robots),
  );
}
