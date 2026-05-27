import 'package:fluffychat/pages/settings_dashboard/settings/settings_view.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../home_robot.dart';

class LanguageSettingRobot extends HomeRobot {
  LanguageSettingRobot(super.$);

  PatrolFinder title() {
    return $(AppBar).$(Text);
  }

  PatrolFinder backIcon() {
    return $(AppBar).$(IconButton);
  }

  PatrolFinder english() {
    return $(ListTile).containing(find.text('English'));
  }

  PatrolFinder french() {
    return $(ListTile).containing(find.text('Français'));
  }

  PatrolFinder russian() {
    return $(ListTile).containing(find.text('Русский'));
  }

  PatrolFinder vietnamese() {
    return $(ListTile).containing(find.text('Tiếng Việt'));
  }

  String? getEnglishInDisplay() {
    return english().$(Text).at(0).text;
  }

  String? getFrenchInDisplay() {
    return french().$(Text).at(0).text;
  }

  String? getRussianInDisplay() {
    return russian().$(Text).at(0).text;
  }

  String? getVietnameseInDisplay() {
    return vietnamese().$(Text).at(0).text;
  }

  Future<void> chooseEnglish() async {
    await english().tap();
    await $.waitUntilVisible(english().$(Icon));
    await $.waitUntilVisible(english().$(Icon));
  }

  Future<void> chooseFrench() async {
    await french().tap();
    await $.waitUntilVisible(french().$(Icon));
  }

  Future<void> chooseRussian() async {
    await russian().tap();
    await $.waitUntilVisible(russian().$(Icon));
  }

  Future<void> chooseVietnamese() async {
    await vietnamese().tap();
    await $.waitUntilVisible(vietnamese().$(Icon));
  }

  String? getSelectedLanguage() {
    final selectedLanguage = $(ListTile).containing($(Icon));
    final text = selectedLanguage.$(Text).at(1).text;
    // Flutter's Material localization renders the Vietnamese display name
    // with different casing depending on the platform — "Tiếng Việt" on
    // mobile vs "Tiếng việt" on web. Normalise to the mobile form so test
    // assertions pass on both.
    if (kIsWeb && text == 'Tiếng việt') return 'Tiếng Việt';
    return text;
  }

  Future<void> backToSettingScreen() async {
    // On wide layouts (web / desktop / tablet) the language screen hides
    // the AppBar back button entirely — see `responsiveUtils.isMobile`
    // check in `SettingsAppLanguageView`. Navigate via the router instead
    // so the scenario converges on mobile and web.
    if (kIsWeb) {
      TwakeApp.router.pop();
      await $.pump();
    } else {
      await backIcon().tap();
    }
    await $.waitUntilVisible($(SettingsView));
  }
}
