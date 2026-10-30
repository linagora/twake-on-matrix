import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../base/api_login_helper_io.dart';
import '../base/base_test_scenario.dart';
import '../robots/setting/device_settings_robot.dart';

// Mobile-only, so it uses the io helper and a concrete robot directly.
class DeviceSettingsScenario extends BaseTestScenario {
  DeviceSettingsScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final name = 'e2e-device-${DateTime.now().millisecondsSinceEpoch}';
    final renamed = '$name-renamed';
    final bulkNames = ['$name-a', '$name-b'];
    final sessions = <PrimaryExtraSession>[];
    try {
      for (final deviceName in [name, ...bulkNames]) {
        sessions.add(
          await loginPrimaryExtraSession(deviceDisplayName: deviceName),
        );
      }
      final [other, ...bulk] = sessions;

      await robots.homeRobot().gotoSettingScreen();
      await robots.settingRobot().openDevicesSetting();

      final devices = DeviceSettingsRobot($);
      await devices.waitForOtherSessions(sessions);
      await devices.expectCurrentSessionCannotBeRemoved();

      await devices.renameSession(other, renamed);
      expect(await other.fetchDisplayName(), renamed);

      await devices.removeSession(other);
      expect(await other.isSignedOut(), isTrue);

      await devices.removeAllOtherSessions();
      for (final session in bulk) {
        expect(await session.isSignedOut(), isTrue);
      }
    } finally {
      for (final session in sessions) {
        // A cleanup error must not hide the test's own failure.
        await session.logout().catchError(
          (Object error) =>
              debugPrint('Cleanup of ${session.deviceId}: $error'),
        );
      }
    }
  }
}
