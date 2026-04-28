import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_view.dart';
import 'package:fluffychat/presentation/widget_keys/widget_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../home_robot.dart';

class SettingsPrivacyAndSecurityRobot extends HomeRobot {
  SettingsPrivacyAndSecurityRobot(super.$);

  PatrolFinder contactVisibilitySetting() {
    return $(find.byKey(SettingsKeys.contactsVisibilityItem.key));
  }

  Future<void> openContactVisibilitySetting() async {
    await contactVisibilitySetting().tap();
    await $.waitUntilVisible($(SettingsContactsVisibilityView));
  }
}
