import 'package:fluffychat/utils/power_level_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:matrix/matrix.dart';

void main() {
  group('PowerLevelManager', () {
    late PowerLevelManager powerLevelManager;

    setUp(() {
      powerLevelManager = PowerLevelManager();
    });

    test('should return correct power levels for each event type', () {
      final userPowerLevel = DefaultPowerLevelMember.user.powerLevel;
      final adminPowerLevel = DefaultPowerLevelMember.admin.powerLevel;
      final result = powerLevelManager.getDefaultPowerLevelEventForMember();

      expect(result[EventTypes.RoomPinnedEvents], equals(userPowerLevel));
      expect(result[EventTypes.RoomName], equals(adminPowerLevel));
      expect(result[EventTypes.RoomAvatar], equals(adminPowerLevel));
      expect(result[EventTypes.RoomMember], equals(userPowerLevel));
      expect(result[EventTypes.RoomTopic], equals(adminPowerLevel));
    });

    test('should contain all expected event types', () {
      final result = powerLevelManager.getDefaultPowerLevelEventForMember();
      expect(
        result.keys,
        containsAll([
          EventTypes.RoomPinnedEvents,
          EventTypes.RoomName,
          EventTypes.RoomAvatar,
          EventTypes.RoomMember,
          EventTypes.RoomTopic,
        ]),
      );
    });
  });
}
