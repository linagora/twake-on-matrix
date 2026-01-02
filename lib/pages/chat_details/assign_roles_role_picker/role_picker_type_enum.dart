import 'package:fluffychat/config/default_power_level_member.dart';

enum RolePickerTypeEnum {
  addAdminOrModerator,
  all,
  none;

  List<DefaultPowerLevelMember> get assignRoles {
    switch (this) {
      case RolePickerTypeEnum.addAdminOrModerator:
        return [
          DefaultPowerLevelMember.moderator,
          DefaultPowerLevelMember.admin,
        ];
      case RolePickerTypeEnum.all:
        return [
          DefaultPowerLevelMember.guest,
          DefaultPowerLevelMember.member,
          DefaultPowerLevelMember.moderator,
          DefaultPowerLevelMember.admin,
        ];
      case RolePickerTypeEnum.none:
        return [];
    }
  }
}
