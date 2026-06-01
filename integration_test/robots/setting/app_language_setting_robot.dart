import 'package:fluffychat/pages/settings_dashboard/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../abstract/abstract_language_setting_robot.dart';
import '../home_robot.dart';

class LanguageSettingRobot extends HomeRobot
    implements AbstractLanguageSettingRobot {
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

  @override
  Future<void> chooseEnglish() async {
    await english().tap();
    await $.waitUntilVisible(english().$(Icon));
    await $.waitUntilVisible(english().$(Icon));
  }

  @override
  Future<void> chooseFrench() async {
    await french().tap();
    await $.waitUntilVisible(french().$(Icon));
  }

  @override
  Future<void> chooseRussian() async {
    await russian().tap();
    await $.waitUntilVisible(russian().$(Icon));
  }

  @override
  Future<void> chooseVietnamese() async {
    await vietnamese().tap();
    await $.waitUntilVisible(vietnamese().$(Icon));
  }

  /// Mobile implementation — returns the text as-is.
  /// Web uses [WebLanguageSettingRobot] which normalises Vietnamese casing.
  @override
  String? getSelectedLanguage() {
    final selectedLanguage = $(ListTile).containing($(Icon));
    return selectedLanguage.$(Text).at(1).text;
  }

  /// Mobile implementation — taps the AppBar back button.
  /// Web uses [WebLanguageSettingRobot] which navigates via the router.
  @override
  Future<void> backToSettingScreen() async {
    await backIcon().tap();
    await $.waitUntilVisible($(SettingsView));
  }
}
