import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'chat_list_robot.dart';
import 'contact_list_robot.dart';
import 'setting/setting_robot.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class HomeRobot extends CoreRobot {
  HomeRobot(super.$);

  Future<PatrolFinder> getContactTab() async {
    return $(TwakeNavigationIcon).at(0);
  }

  Future<PatrolFinder> getChatTab() async {
    return $(TwakeNavigationIcon).at(1);
  }

  Future<PatrolFinder> getSettingTab() async {
    return $('Settings');
  }

  Future<void> confirmShareContactInformation() async {
    final dialog = $(PermissionDialog);
    if (dialog.exists) {
      final ctx = $.tester.element(dialog); // BuildContext inside dialog
      final nextLabel = L10n.of(ctx)!.next; // whatever the app shows

      await $.tester
          .tap(find.descendant(of: dialog, matching: find.text(nextLabel)));
      await $.tester.pumpAndSettle();
    }
  }

  Future<void> confirmAccessContactIOS() async {
    try {
      await $.native.waitUntilVisible(
        Selector(textContains: 'OK'),
        appId: 'com.apple.springboard',
      );
      await $.native.tap(
        Selector(textContains: 'OK'),
        appId: 'com.apple.springboard',
      );
    } catch (e) {
      ignoreException();
    }
  }

  Future<ContactListRobot> gotoContactListAndGrantContactPermission() async {
    await (await getContactTab()).tap();
    await confirmShareContactInformation();
    await confirmAccessContactIOS();

    await $.pumpAndSettle();
    return ContactListRobot($);
  }

  Future<ChatListRobot> gotoChatListScreen() async {
    await (await getChatTab()).tap();
    await $.pumpAndSettle();
    return ChatListRobot($);
  }

  Future<SettingRobot> gotoSettingScreen() async {
    await (await getSettingTab()).tap();
    await $.pumpAndSettle();
    return SettingRobot($);
  }
}
