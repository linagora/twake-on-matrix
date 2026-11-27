import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/default_power_level_member.dart';

import '../base/base_test_scenario.dart';
import '../base/throwaway_group.dart';
import '../robots/room_members_robot.dart';

const _member = String.fromEnvironment('MemberMatrixID');
const _otherMember = String.fromEnvironment('SearchByMatrixAddress');

/// Promote a member to admin from the long-press menu of Group info.
class PromoteMemberToAdminScenario extends BaseTestScenario {
  PromoteMemberToAdminScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() => runInThrowawayGroup(
    this,
    titlePrefix: 'Members promote',
    invite: const [_member],
    body: (room) async {
      await RoomMembersRobot($).promoteToAdmin(_member);
      await waitForSync(
        this,
        () =>
            room.getPowerLevelByUserId(_member) ==
            DefaultPowerLevelMember.admin.powerLevel,
        'the admin power level',
      );
    },
  );
}

/// Select two members, then remove them together.
class RemoveSelectedMembersScenario extends BaseTestScenario {
  RemoveSelectedMembersScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() => runInThrowawayGroup(
    this,
    titlePrefix: 'Members select',
    invite: const [_member, _otherMember],
    body: (room) async {
      await RoomMembersRobot($).removeTogether(const [_member, _otherMember]);
      await waitForSync(
        this,
        () =>
            membershipOf(room, _member) == Membership.ban.name &&
            membershipOf(room, _otherMember) == Membership.ban.name,
        'both bans',
      );
    },
  );
}

/// Lift a ban from the Removed Users page reached from Edit.
class UnbanFromRemovedUsersScenario extends BaseTestScenario {
  UnbanFromRemovedUsersScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() => runInThrowawayGroup(
    this,
    titlePrefix: 'Members unban',
    invite: const [_otherMember],
    body: (room) async {
      await room.ban(_otherMember);
      await waitForSync(
        this,
        () => membershipOf(room, _otherMember) == Membership.ban.name,
        'the ban',
      );
      final displayName = room
          .unsafeGetUserFromMemoryOrFallback(_otherMember)
          .calcDisplayname();

      final members = RoomMembersRobot($);
      await members.openRemovedUsers();
      await members.unban(displayName);
      await waitForSync(
        this,
        () => membershipOf(room, _otherMember) == Membership.leave.name,
        'the unban',
      );
    },
  );
}
