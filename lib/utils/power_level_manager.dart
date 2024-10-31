import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:matrix/matrix.dart';

class PowerLevelManager {
  static final PowerLevelManager _instance = PowerLevelManager._internal();

  PowerLevelManager._internal();

  factory PowerLevelManager() {
    return _instance;
  }

  int getUserPowerLevel() {
    return DefaultPowerLevelMember.user.powerLevel;
  }

  int getAdminPowerLevel() => DefaultPowerLevelMember.admin.powerLevel;

  Map<String, dynamic> getDefaultPowerLevelEventForMember() {
    return {
      EventTypes.RoomPinnedEvents: getUserPowerLevel(),
      EventTypes.RoomName: getAdminPowerLevel(),
      EventTypes.RoomAvatar: getAdminPowerLevel(),
      EventTypes.RoomMember: getUserPowerLevel(),
      EventTypes.RoomTopic: getAdminPowerLevel(),
    };
  }
}
