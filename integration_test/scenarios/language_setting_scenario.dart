import 'package:fluffychat/pages/settings_dashboard/settings/settings_view.dart';

import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/abstract/abstract_language_setting_robot.dart';

/// Cross-platform scenario for the app-language settings screen.
///
/// Switches the app language through Vietnamese, French, Russian and back to
/// English, asserting after each switch that every option label is
/// re-localised, then navigates back to the settings screen.
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`, so the same scenario runs on mobile and web.
class LanguageSettingScenario extends BaseTestScenario {
  LanguageSettingScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();
    final language = robots.languageSettingRobot();

    await robots.homeRobot().gotoSettingScreen();
    await robots.settingRobot().openAppLanguageSetting();

    for (final expectation in _expectations) {
      await expectation.choose(language);
      _verifyLabels(s, language, expectation);
    }

    await language.backToSettingScreen();
    s.softAssertEquals(
      $(SettingsView).exists,
      true,
      'did not navigate back to Setting View',
    );

    s.verifyAll();
  }

  /// Asserts that, after selecting a language, the selected value and every
  /// option label match the expectation (the list re-localises into the
  /// active language).
  void _verifyLabels(
    SoftAssertHelper s,
    AbstractLanguageSettingRobot language,
    _LanguageExpectation expected,
  ) {
    void check(String? actual, String want, String field) {
      s.softAssertEquals(
        actual == want,
        true,
        'expected $field "$want" but it is "$actual"',
      );
    }

    check(language.getSelectedLanguage(), expected.selected, 'selected');
    check(language.getEnglishInDisplay(), expected.english, 'English label');
    check(language.getFrenchInDisplay(), expected.french, 'French label');
    check(language.getRussianInDisplay(), expected.russian, 'Russian label');
    check(
      language.getVietnameseInDisplay(),
      expected.vietnamese,
      'Vietnamese label',
    );
  }

  /// One entry per language switch: the action plus the labels expected once
  /// the UI has re-localised into that language.
  static final List<_LanguageExpectation> _expectations = [
    _LanguageExpectation(
      choose: (r) => r.chooseVietnamese(),
      selected: 'Tiếng Việt',
      english: 'Tiếng anh',
      french: 'Tiếng pháp',
      russian: 'Tiếng nga',
      vietnamese: 'Tiếng việt',
    ),
    _LanguageExpectation(
      choose: (r) => r.chooseFrench(),
      selected: 'Français',
      english: 'Anglais',
      french: 'Français',
      russian: 'Russe',
      vietnamese: 'Vietnamien',
    ),
    _LanguageExpectation(
      choose: (r) => r.chooseRussian(),
      selected: 'Русский',
      english: 'Английский',
      french: 'Французский',
      russian: 'Русский',
      vietnamese: 'Вьетнамский',
    ),
    _LanguageExpectation(
      choose: (r) => r.chooseEnglish(),
      selected: 'English',
      english: 'English',
      french: 'French',
      russian: 'Russian',
      vietnamese: 'Vietnamese',
    ),
  ];
}

/// A single language switch and the option labels expected afterwards.
class _LanguageExpectation {
  const _LanguageExpectation({
    required this.choose,
    required this.selected,
    required this.english,
    required this.french,
    required this.russian,
    required this.vietnamese,
  });

  final Future<void> Function(AbstractLanguageSettingRobot robot) choose;
  final String selected;
  final String english;
  final String french;
  final String russian;
  final String vietnamese;
}
