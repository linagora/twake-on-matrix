import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_chat/settings_chat_view.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/settings_switch_list_tile.dart';

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

  /// Waits until the tile shows the value read from storage, not the
  /// default it renders while that read is still pending.
  Future<bool> waitForStoredValue(
    String title, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final tileFinder = find.ancestor(
      of: find.text(title),
      matching: find.byType(SettingsSwitchListTile),
    );
    await $.waitUntilExists($(tileFinder));
    final tile = $.tester.widget<SettingsSwitchListTile>(tileFinder.first);
    final context = $.tester.element(tileFinder.first);
    final stored = await Matrix.of(
      context,
    ).store.getItemBool(tile.storeKey, tile.defaultValue);
    final end = DateTime.now().add(timeout);
    while (isSwitchOn(title) != stored) {
      if (DateTime.now().isAfter(end)) {
        throw StateError('"$title" switch never showed its stored value');
      }
      await $.pump(const Duration(milliseconds: 100));
    }
    return stored;
  }

  bool isSwitchOn(String title) {
    final tile = $.tester.widget<SwitchListTile>(switchTile(title).first);
    return tile.value;
  }

  Future<void> toggleSwitch(String title) async {
    final before = await waitForStoredValue(title);
    await switchTile(title).tap();
    final end = DateTime.now().add(const Duration(seconds: 10));
    while (isSwitchOn(title) == before) {
      if (DateTime.now().isAfter(end)) {
        throw StateError('"$title" switch did not change after tapping it');
      }
      await $.pump(const Duration(milliseconds: 100));
    }
    await $.pumpAndSettle();
  }

  /// Writes [value] for the [title] setting the same way the tile does
  /// (its `onChanged`, then storage), without waiting for the switch to show
  /// it. Used for cleanup, so it still works when the switch is out of sync.
  Future<void> restoreStoredValue(String title, bool value) async {
    final tileFinder = find.ancestor(
      of: find.text(title),
      matching: find.byType(SettingsSwitchListTile),
    );
    await $.waitUntilExists($(tileFinder));
    final tile = $.tester.widget<SettingsSwitchListTile>(tileFinder.first);
    final context = $.tester.element(tileFinder.first);
    tile.onChanged?.call(value);
    await Matrix.of(context).store.setItemBool(tile.storeKey, value);
  }

  Future<void> backToSettingScreen() async {
    await goBack();
    await $.pumpAndSettle();
  }
}
