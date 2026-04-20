import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'chat_list_robot.dart';
import 'contact_list_robot.dart';
import 'setting/setting_robot.dart';

class HomeRobot extends CoreRobot {
  HomeRobot(super.$);

  Future<PatrolFinder> getContactTab() async {
    return $(TwakeNavigationIcon).at(0);
  }

  Future<PatrolFinder> getChatTab() async {
    return $(TwakeNavigationIcon).at(1);
  }

  Future<PatrolFinder> getSettingTab() async {
    // On wide layouts (web / desktop / tablet) the adaptive scaffold
    // converts each `NavigationDestination` into a `NavigationRailDestination`
    // via `AdaptiveScaffold.toRailDestination`, which drops the widget Key —
    // `NavigationRailDestination` has no Key parameter in the Flutter API.
    // Fall back to the settings icon when the keyed finder has no match.
    if (kIsWeb) {
      return $(find.byIcon(Icons.settings_outlined).first);
    }
    return $(const Key('settings_navigation_destination'));
  }

  Future<ContactListRobot> gotoContactListScreen() async {
    await (await getContactTab()).tap();
    await confirmShareContactInformation();
    await confirmAccessContact();

    await $.pumpAndSettle();
    return ContactListRobot($);
  }

  Future<ChatListRobot> gotoChatListScreen() async {
    await (await getChatTab()).tap();
    await $.pumpAndSettle();
    return ChatListRobot($);
  }

  Future<SettingRobot> gotoSettingScreen() async {
    final settingTab = await getSettingTab();
    await settingTab.tap();
    await $.pumpAndSettle();
    return SettingRobot($);
  }
}
