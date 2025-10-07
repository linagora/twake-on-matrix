import 'package:fluffychat/pages/settings_dashboard/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'setting_robot.dart';

class NotificationSettingRobot extends SettingRobot {
  NotificationSettingRobot(super.$);

  @override
  PatrolFinder title() {
    return $(AppBar).$(Text);
  }

  PatrolFinder backIcon() {
    return $(AppBar).$(IconButton);
  }

  PatrolFinder diableNotificationToggle() {
    return $(SwitchListTile).containing(find.text('Disable notifications'));
  }

  PatrolFinder directChatsToggleToggle() {
    return $(SwitchListTile).containing(find.text('Direct Chats'));
  }

  PatrolFinder containsDisplayNameToggle() {
    return $(SwitchListTile).containing(find.text('Contains display name'));
  }

  PatrolFinder containsUsernameToggle() {
    return $(ListTile).containing(find.text('Contains username'));
  }
  
  PatrolFinder inviteForMeToggle() {
    return $(ListTile).containing(find.text('Invite for me"'));
  }

  PatrolFinder memberChangesToggle() {
    return $(ListTile).containing(find.text('Member changes'));
  }

  PatrolFinder botMessageToggle() {
    return $(ListTile).containing(find.text('Bot messages'));
  }

  Future<void> backToSettingScreen() async{
    await backIcon().tap();
    await $.waitUntilVisible($(SettingsView));
  } 

  bool isTurnOn(PatrolFinder toggle) {
    final w = toggle.evaluate().single.widget as SwitchListTile;
    return w.value;
  }

  Future<void> turnOffDisableNotification() async{
    if(isTurnOn(diableNotificationToggle()))
    {
      await diableNotificationToggle().tap();
      await waitUntil(() => !isTurnOn(diableNotificationToggle()), timeout: const Duration(seconds: 10));
    }
  } 

    Future<void> turnOnNotificationForDirectChat() async{
    if(!isTurnOn(directChatsToggleToggle()))
    {
      await directChatsToggleToggle().tap();
      await waitUntil(() => isTurnOn(directChatsToggleToggle()), timeout: const Duration(seconds: 10));
    }
  }

  Future<void> turnOffNotificationForDirectChat() async{
    if(isTurnOn(directChatsToggleToggle()))
    {
      await directChatsToggleToggle().tap();
      await waitUntil(() => !isTurnOn(directChatsToggleToggle()), timeout: const Duration(seconds: 10));
    }
  } 
}
