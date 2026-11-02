import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_chat/settings_chat_view.dart';

import '../home_robot.dart';

/// Drives the Settings > Chat screen on mobile.
class SettingsChatRobot extends HomeRobot {
  SettingsChatRobot(super.$);

  static const gifAutoplayTitle = 'GIF autoplay';

  PatrolFinder view() => $(SettingsChatView);

  PatrolFinder switchTile(String title) =>
      $(SwitchListTile).containing(find.text(title));

  Future<void> waitForView() async {
    await $.waitUntilVisible(view());
  }

  bool isSwitchOn(String title) {
    final tile = $.tester.widget<SwitchListTile>(switchTile(title).first);
    return tile.value;
  }

  Future<void> toggleSwitch(String title) async {
    final before = isSwitchOn(title);
    await switchTile(title).tap();
    await $.pumpAndSettle();
    if (isSwitchOn(title) == before) {
      throw StateError('"$title" switch did not change after tapping it');
    }
  }

  Future<void> backToSettingScreen() async {
    await goBack();
    await $.pumpAndSettle();
  }
}
