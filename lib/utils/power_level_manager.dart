import 'package:twake_chat/config/default_power_level_member.dart';
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

  /// Out of reach of everyone but the room creator: freezes a state event for
  /// the whole lifetime of the room.
  int getFrozenPowerLevel() => DefaultPowerLevelMember.none.powerLevel;

  Map<String, dynamic> getDefaultPowerLevelEventForMember() {
    return {
      EventTypes.RoomPinnedEvents: getUserPowerLevel(),
      EventTypes.RoomName: getAdminPowerLevel(),
      EventTypes.RoomAvatar: getAdminPowerLevel(),
      EventTypes.RoomMember: getUserPowerLevel(),
      EventTypes.RoomTopic: getAdminPowerLevel(),
    };
  }

  /// Sent with the feed preset so the room is identical whatever the
  /// preset the homeserver applies on its side.
  Map<String, dynamic> getFeedPowerLevelContentOverride() {
    return {
      'users_default': getUserPowerLevel(),
      'events_default': getAdminPowerLevel(),
      'state_default': getAdminPowerLevel(),
      'invite': getAdminPowerLevel(),
      'kick': getAdminPowerLevel(),
      'ban': getAdminPowerLevel(),
      'redact': getAdminPowerLevel(),
      'events': {
        EventTypes.Reaction: getUserPowerLevel(),
        EventTypes.Redaction: getUserPowerLevel(),
        EventTypes.RoomMember: getUserPowerLevel(),
        EventTypes.Encryption: getFrozenPowerLevel(),
        EventTypes.HistoryVisibility: getFrozenPowerLevel(),
        EventTypes.RoomTombstone: getFrozenPowerLevel(),
      },
      'notifications': {'room': getAdminPowerLevel()},
    };
  }
}
