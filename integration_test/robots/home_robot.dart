import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/floating_navigation_bar.dart';
import '../base/core_robot.dart';
import 'abstract/abstract_home_robot.dart';
import 'chat_list_robot.dart';
import 'contact_list_robot.dart';
import 'setting/setting_robot.dart';

class HomeRobot extends CoreRobot implements AbstractHomeRobot {
  HomeRobot(super.$);

  @override
  bool isMainNavigationVisible() =>
      $(FloatingNavigationBar).visible || $(NavigationRail).visible;

  @override
  Future<void> waitForMainNavigation({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await waitForEitherVisible(
      $: $,
      first: $(FloatingNavigationBar),
      second: $(NavigationRail),
      timeout: timeout,
    );
  }

  Future<PatrolFinder> getContactTab() async {
    return $(TwakeNavigationIcon).at(0);
  }

  Future<PatrolFinder> getChatTab() async {
    return $(TwakeNavigationIcon).at(1);
  }

  /// The rail's Settings destination on a wide screen, else the account
  /// avatar of the Chats header.
  Future<PatrolFinder> getSettingTab() async {
    final railDestination = $(
      find.byKey(NavigationKeys.settingsDestination.key),
    );
    if (railDestination.exists) return railDestination;
    final avatar = $(find.byKey(NavigationKeys.accountAvatar.key));
    if (!avatar.exists) await gotoChatListScreen();
    return avatar;
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
