import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:matrix/matrix.dart';

extension UserExtension on User {
  DefaultPowerLevelMember get getDefaultPowerLevelMember {
    switch (powerLevel) {
      case 0:
        return DefaultPowerLevelMember.user;
      case 50:
        return DefaultPowerLevelMember.moderator;
      case 80:
        return DefaultPowerLevelMember.admin;
      case 100:
        return DefaultPowerLevelMember.owner;
      default:
        return DefaultPowerLevelMember.user;
    }
  }

  bool get isOwnerRole {
    return getDefaultPowerLevelMember == DefaultPowerLevelMember.owner;
  }
}
