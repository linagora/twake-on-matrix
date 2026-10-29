import 'package:flutter_test/flutter_test.dart';

import '../base/api_login_helper_io.dart';
import '../base/base_test_scenario.dart';
import '../robots/setting/device_settings_robot.dart';

class DeviceSettingsScenario extends BaseTestScenario {
  DeviceSettingsScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final name = 'e2e-device-${DateTime.now().millisecondsSinceEpoch}';
    final renamed = '$name-renamed';
    final other = await loginPrimaryExtraSession(deviceDisplayName: name);
    try {
      await robots.homeRobot().gotoSettingScreen();
      await robots.settingRobot().openDevicesSetting();

      final devices = DeviceSettingsRobot($);
      await devices.waitForOtherSession(name);
      await devices.expectCurrentSessionCannotBeRemoved();

      await devices.renameSession(name, renamed);
      expect(await other.serverDisplayName(), renamed);

      await devices.removeSession(
        renamed,
        password: const String.fromEnvironment('PASSWORD'),
      );
      expect(await other.isSignedOut(), isTrue);
    } finally {
      await other.logout();
    }
  }
}
