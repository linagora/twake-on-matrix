import 'package:flutter_test/flutter_test.dart';
import '../base/base_scenario.dart';
import '../robots/setting/notification_setting_robot.dart';
import '../robots/setting/setting_robot.dart';

class SettingScenario extends BaseScenario {
  SettingScenario(super.$);

  Future<void> turnOnNotificationForDirectChat() async {
    await SettingRobot($).openNotificationSetting();
    await NotificationSettingRobot($).turnOnNotificationForDirectChat();
  }
  
  Future<void> turnOffNotificationForDirectChat() async {
    await SettingRobot($).openNotificationSetting();
    await NotificationSettingRobot($).turnOffNotificationForDirectChat();
  }
}
