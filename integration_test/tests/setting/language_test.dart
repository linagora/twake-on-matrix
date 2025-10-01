import 'package:fluffychat/pages/settings_dashboard/settings/settings_view.dart';
import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/home_robot.dart';
import '../../robots/setting/app_language_setting_robot.dart';
import '../../robots/setting/setting_robot.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'verify action on App Language screen',
    test: ($) async {
      final s = SoftAssertHelper();
      // goto setting screen
      await HomeRobot($).gotoSettingScreen();
      //open setting for language
      await SettingRobot($).openAppLanguageSetting();

      // set Vietname language for app
      await LanguageSettingRobot($).chooseVietnamese();
      //verify text is change to VietName
      String? language = LanguageSettingRobot($).getSelectedLanguage();
      s.softAssertEquals(language == "Tiếng Việt", true, 'expected language is Tiếng Việt but it is $language');
      s.softAssertEquals(LanguageSettingRobot($).getEnglishInDisplay() == "Tiếng anh", true,
       'expected language is Tiếng Anh but it is ${LanguageSettingRobot($).getEnglishInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getFrenchInDisplay()== "Tiếng pháp", true,
       'expected language is Tiếng Pháp but it is ${LanguageSettingRobot($).getFrenchInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getRussianInDisplay()== "Tiếng nga", true,
       'expected language is Tiếng Nga but it is ${LanguageSettingRobot($).getRussianInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getVietnameseInDisplay() == "Tiếng việt", true,
       'expected language is Tiếng việt but it is ${LanguageSettingRobot($).getVietnameseInDisplay()}',);

      // set French language for app
      await LanguageSettingRobot($).chooseFrench();
      //verify text is change to VietName
      language = LanguageSettingRobot($).getSelectedLanguage();
      s.softAssertEquals(language == "Français", true, 'expected language is Français but it is $language');
      s.softAssertEquals(LanguageSettingRobot($).getEnglishInDisplay() == "Anglais", true,
       'expected language is Anglais but it is ${LanguageSettingRobot($).getEnglishInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getFrenchInDisplay() == "Français", true,
       'expected language is Français but it is ${LanguageSettingRobot($).getFrenchInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getRussianInDisplay() == "Russe", true,
       'expected language is Russe but it is ${LanguageSettingRobot($).getRussianInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getVietnameseInDisplay() == "Vietnamien", true,
       'expected language is Vietnamien but it is ${LanguageSettingRobot($).getVietnameseInDisplay()}',);

      // set Russian language for app
      await LanguageSettingRobot($).chooseRussian();
      //verify text is change to VietName
      language = LanguageSettingRobot($).getSelectedLanguage();
      s.softAssertEquals(language == "Русский", true, 'expected language is Русский but it is $language');
      s.softAssertEquals(LanguageSettingRobot($).getEnglishInDisplay() == "Английский", true,
       'expected language is Английский but it is ${LanguageSettingRobot($).getEnglishInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getFrenchInDisplay() == "Французский", true,
       'expected language is Французский but it is ${LanguageSettingRobot($).getFrenchInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getRussianInDisplay() == "Русский", true,
       'expected language is Русский but it is ${LanguageSettingRobot($).getRussianInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getVietnameseInDisplay() == "Вьетнамский", true,
       'expected language is Вьетнамский but it is ${LanguageSettingRobot($).getVietnameseInDisplay()}',);

      // set english language for app
      await LanguageSettingRobot($).chooseEnglish();
      //verify text is change to VietName
      language = LanguageSettingRobot($).getSelectedLanguage();
      s.softAssertEquals(language == "English", true, 'expected language is English but it is $language');
      s.softAssertEquals(LanguageSettingRobot($).getEnglishInDisplay() == "English", true,
       'expected language is English but it is ${LanguageSettingRobot($).getEnglishInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getFrenchInDisplay() == "French", true,
       'expected language is French but it is ${LanguageSettingRobot($).getFrenchInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getRussianInDisplay() == "Russian", true,
       'expected language is Russian but it is ${LanguageSettingRobot($).getRussianInDisplay()}',);
      s.softAssertEquals(LanguageSettingRobot($).getVietnameseInDisplay() == "Vietnamese", true,
       'expected language is Vietnamese but it is ${LanguageSettingRobot($).getVietnameseInDisplay()}',);

      //can back to Setting screen
      await LanguageSettingRobot($).backToSettingScreen();
      s.softAssertEquals($(SettingsView).exists, true, 'still back to Setting View');

      s.verifyAll();
    
    },
  );
}