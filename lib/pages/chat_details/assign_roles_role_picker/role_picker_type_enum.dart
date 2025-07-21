import 'package:fluffychat/config/default_power_level_member.dart';

enum RolePickerTypeEnum {
  addAdminOrModerator,
  none;

  List<DefaultPowerLevelMember> get assignRoles {
    switch (this) {
      case RolePickerTypeEnum.addAdminOrModerator:
        return [
          DefaultPowerLevelMember.moderator,
          DefaultPowerLevelMember.admin,
        ];
      case RolePickerTypeEnum.none:
        return [];
    }
  }
}
