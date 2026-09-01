import 'package:twake_chat/utils/power_level_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/default_power_level_member.dart';
import 'package:matrix/matrix.dart';

void main() {
  group('PowerLevelManager', () {
    late PowerLevelManager powerLevelManager;

    setUp(() {
      powerLevelManager = PowerLevelManager();
    });

    test('should return correct power levels for each event type', () {
      final userPowerLevel = DefaultPowerLevelMember.member.powerLevel;
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

    group('getFeedPowerLevelContentOverride', () {
      final userPowerLevel = DefaultPowerLevelMember.member.powerLevel;
      final adminPowerLevel = DefaultPowerLevelMember.admin.powerLevel;
      final frozenPowerLevel = DefaultPowerLevelMember.none.powerLevel;

      test('should restrict publishing and administration to admins', () {
        final result = powerLevelManager.getFeedPowerLevelContentOverride();

        expect(result['users_default'], equals(userPowerLevel));
        expect(result['events_default'], equals(adminPowerLevel));
        expect(result['state_default'], equals(adminPowerLevel));
        expect(result['invite'], equals(adminPowerLevel));
        expect(result['kick'], equals(adminPowerLevel));
        expect(result['ban'], equals(adminPowerLevel));
        expect(result['redact'], equals(adminPowerLevel));
        expect(result['notifications'], equals({'room': adminPowerLevel}));
      });

      test('should let the audience react and undo its own reactions', () {
        final events =
            powerLevelManager.getFeedPowerLevelContentOverride()['events']
                as Map<String, dynamic>;

        expect(events[EventTypes.Reaction], equals(userPowerLevel));
        expect(events[EventTypes.Redaction], equals(userPowerLevel));
      });

      test('should freeze encryption, history visibility and tombstone', () {
        final events =
            powerLevelManager.getFeedPowerLevelContentOverride()['events']
                as Map<String, dynamic>;

        expect(events[EventTypes.Encryption], equals(frozenPowerLevel));
        expect(events[EventTypes.HistoryVisibility], equals(frozenPowerLevel));
        expect(events[EventTypes.RoomTombstone], equals(frozenPowerLevel));
      });

      test('should keep the audience below the publishing level', () {
        final result = powerLevelManager.getFeedPowerLevelContentOverride();

        expect(
          result['users_default'] as int,
          lessThan(result['events_default'] as int),
        );
      });
    });
  });
}
