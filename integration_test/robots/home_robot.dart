import 'package:fluffychat/presentation/widget_keys/widget_keys.dart';
import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'abstract/abstract_home_robot.dart';
import 'chat_list_robot.dart';
import 'contact_list_robot.dart';
import 'setting/setting_robot.dart';

class HomeRobot extends CoreRobot implements AbstractHomeRobot {
  HomeRobot(super.$);

  Future<PatrolFinder> getContactTab() async {
    return $(TwakeNavigationIcon).at(0);
  }

  Future<PatrolFinder> getChatTab() async {
    return $(TwakeNavigationIcon).at(1);
  }

  Future<PatrolFinder> getSettingTab() async {
    final byKey = $(find.byKey(NavigationKeys.settingsDestination.key));
    if (byKey.exists) return byKey;
    // On web the NavigationRail loses the widget key during
    // toRailDestination() conversion — fall back to the icon.
    return $(NavigationRail).$(find.byIcon(Icons.settings_outlined)).first;
  }

  @override
  Future<ContactListRobot> gotoContactListScreen() async {
    await (await getContactTab()).tap();
    await confirmShareContactInformation();
    await confirmAccessContact();

    await $.pumpAndSettle();
    return ContactListRobot($);
  }

  @override
  Future<ChatListRobot> gotoChatListScreen() async {
    await (await getChatTab()).tap();
    await $.pumpAndSettle();
    return ChatListRobot($);
  }

  @override
  Future<SettingRobot> gotoSettingScreen() async {
    final settingTab = await getSettingTab();
    await settingTab.tap();
    await $.pumpAndSettle();
    return SettingRobot($);
  }
}
