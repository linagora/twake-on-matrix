import 'package:fluffychat/pages/device_settings/device_settings_view.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_app_language/settings_app_language.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_chat/settings_chat_view.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_notifications/settings_notifications_view.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_security/settings_security_view.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/dialog/confirmation_dialog_builder.dart';
import 'package:patrol/patrol.dart';
import '../../base/core_robot.dart';

class SettingRobot extends CoreRobot {
  SettingRobot(super.$);

  PatrolFinder title() {
    return $(AppBar).$(Text);
  }

  PatrolFinder chatSetting() {
    return $("Chat");
  }

  PatrolFinder privateAndSecuritySetting() {
    return $("Privacy & Security");
  }

  PatrolFinder notificationsSetting() {
    return $("Notifications");
  }

  PatrolFinder appLanguageSetting() {
    return $("App Language");
  }

  PatrolFinder deviceSetting() {
    return $("Devices");
  }
   
  PatrolFinder helpSetting() {
    return $("Help");
  }

  PatrolFinder about() {
    return $("About");
  }

  PatrolFinder logout() {
    return $("Logout");
  }
  
  Future<void> openChatSetting() async{
    await chatSetting().tap();
    await $.waitUntilVisible($(SettingsChatView));
  }

  Future<void> openPrivacyAndSecuritySetting() async{
    await privateAndSecuritySetting().tap();
    await $.waitUntilVisible($(SettingsSecurityView));
  }

  Future<void> openNotificationSetting() async{
    await notificationsSetting().tap();
    await $.waitUntilVisible($(SettingsNotificationsView));
  }

  Future<void> openAppLanguageSetting() async{
    await appLanguageSetting().tap();
    await $.waitUntilVisible($(SettingsAppLanguage));
  }

  Future<void> openDevicesSetting() async{
    await deviceSetting().tap();
    await $.waitUntilVisible($(DevicesSettingsView));
  }

  Future<void> viewAboutInfo() async{
    await about().tap();
    await $.waitUntilVisible($(Text).containing('Version:'));
  }

  Future<void> logoutOfApp() async{
    await logout().tap();
    await $.waitUntilVisible($(ConfirmationDialogBuilder));
  }
}
