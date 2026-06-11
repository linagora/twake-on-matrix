/// Platform-agnostic contract for the main settings screen.
///
/// Opening sub-settings pages and the logout action are the methods
/// scenarios typically call.
abstract class AbstractSettingRobot {
  Future<void> openChatSetting();
  Future<void> openPrivacyAndSecuritySetting();
  Future<void> openNotificationSetting();
  Future<void> openAppLanguageSetting();
  Future<void> openDevicesSetting();
  Future<void> viewAboutInfo();
  Future<void> logoutOfApp();
}
