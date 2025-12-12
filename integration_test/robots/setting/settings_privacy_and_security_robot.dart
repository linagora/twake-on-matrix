import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:patrol/patrol.dart';

import '../home_robot.dart';

class SettingsPrivacyAndSecurityRobot extends HomeRobot {
  SettingsPrivacyAndSecurityRobot(super.$);

  PatrolFinder contactVisibilitySetting() {
    return $(const Key('contacts_visibility_settings_item'));
  }

  Future<void> openContactVisibilitySetting() async {
    await contactVisibilitySetting().tap();
    await $.waitUntilVisible($(SettingsContactsVisibilityView));
  }
}
