import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_chat/settings_chat_view.dart';

import '../home_robot.dart';

/// Drives the Settings > Chat screen on mobile.
class SettingsChatRobot extends HomeRobot {
  SettingsChatRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  String get gifAutoplayTitle => _l10n.gifAutoplay;

  PatrolFinder view() => $(SettingsChatView);

  PatrolFinder switchTile(String title) =>
      $(SwitchListTile).containing(find.text(title));

  Future<void> waitForView() async {
    await $.waitUntilVisible(view());
  }

  /// Waits until the switch of [title] shows [expected]. The tile renders its
  /// default first and the stored value once the read completes, so the
  /// expected value must come from outside the tile.
  Future<void> waitForSwitchValue(String title, bool expected) async {
    await switchTile(title)
        .which<SwitchListTile>((tile) => tile.value == expected)
        .waitUntilVisible();
  }

  /// Taps the switch of [title] once it shows [from] and waits for it to flip.
  Future<void> toggleSwitch(String title, {required bool from}) async {
    await waitForSwitchValue(title, from);
    await switchTile(title).tap();
    await waitForSwitchValue(title, !from);
    await $.pumpAndSettle();
  }

  Future<void> backToSettingScreen() async {
    await goBack();
    await $.pumpAndSettle();
  }
}
