import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:matrix/matrix.dart';

class PowerLevelManager {
  static final PowerLevelManager _instance = PowerLevelManager._internal();

  PowerLevelManager._internal();

  factory PowerLevelManager() {
    return _instance;
  }

  int getUserPowerLevel() {
    return DefaultPowerLevelMember.member.powerLevel;
  }

  int getAdminPowerLevel() => DefaultPowerLevelMember.admin.powerLevel;

  Map<String, dynamic> getDefaultPowerLevelEventForMember() {
    return {
      EventTypes.RoomPinnedEvents: getUserPowerLevel(),
      EventTypes.RoomName: getAdminPowerLevel(),
      EventTypes.RoomAvatar: getAdminPowerLevel(),
      EventTypes.RoomMember: getUserPowerLevel(),
      EventTypes.RoomTopic: getAdminPowerLevel(),
      // MSC1236 widget state event, published when starting a video call.
      'im.vector.modular.widgets': getUserPowerLevel(),
      // Element widget layout, pins the call widget to the top of the room.
      'io.element.widgets.layout': getUserPowerLevel(),
    };
  }
}
