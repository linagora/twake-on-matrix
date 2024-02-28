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

  Map<String, dynamic> getDefaultPowerLevelEventForMember() {
    return {
      EventTypes.RoomPinnedEvents: getUserPowerLevel(),
      EventTypes.RoomName: getUserPowerLevel(),
      EventTypes.RoomAvatar: getUserPowerLevel(),
      EventTypes.RoomMember: getUserPowerLevel(),
      EventTypes.RoomTopic: getUserPowerLevel(),
    };
  }
}
