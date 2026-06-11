/// Platform-agnostic contract for the app-language settings screen.
///
/// Known divergences:
/// - `backToSettingScreen`: web uses `TwakeApp.router.pop()` because the
///   AppBar back button is hidden on wide layouts (`responsiveUtils.isMobile`).
/// - `getSelectedLanguage`: Flutter's intl data renders Vietnamese as
///   "Tiếng việt" on web vs "Tiếng Việt" on mobile — normalisation needed.
abstract class AbstractLanguageSettingRobot {
  Future<void> chooseEnglish();
  Future<void> chooseFrench();
  Future<void> chooseRussian();
  Future<void> chooseVietnamese();
  String? getSelectedLanguage();

  /// The label of each language option as currently rendered in the list,
  /// i.e. translated into the app's active language. Scenarios assert these
  /// to verify the UI re-localises after a language switch.
  String? getEnglishInDisplay();
  String? getFrenchInDisplay();
  String? getRussianInDisplay();
  String? getVietnameseInDisplay();

  Future<void> backToSettingScreen();
}
