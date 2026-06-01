import 'package:fluffychat/pages/settings_dashboard/settings/settings_view.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../setting/app_language_setting_robot.dart';

/// Web-specific language-setting robot.
///
/// Two known divergences from mobile:
/// - `getSelectedLanguage`: Flutter's intl data renders Vietnamese as
///   "Tiếng việt" on web vs "Tiếng Việt" on mobile — normalise here.
/// - `backToSettingScreen`: on wide layouts the AppBar back button is
///   hidden (`responsiveUtils.isMobile` check in
///   `SettingsAppLanguageView`). Navigate via the router instead.
class WebLanguageSettingRobot extends LanguageSettingRobot {
  WebLanguageSettingRobot(super.$);

  @override
  String? getSelectedLanguage() {
    final selectedLanguage = $(ListTile).containing($(Icon));
    final text = selectedLanguage.$(Text).at(1).text;
    // Normalise "Tiếng việt" → "Tiếng Việt" so test assertions match mobile.
    if (text == 'Tiếng việt') return 'Tiếng Việt';
    return text;
  }

  @override
  Future<void> backToSettingScreen() async {
    // On wide layouts the AppBar back button is hidden entirely — navigate
    // via the router so the scenario converges.
    TwakeApp.router.pop();
    await $.pump();
    await $.waitUntilVisible($(SettingsView));
  }
}
