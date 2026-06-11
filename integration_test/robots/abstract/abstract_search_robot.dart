/// Platform-agnostic contract for the search screen.
///
/// `backToPreviousScreen` already diverges: mobile waits for
/// `BottomNavigationBar`, web skips that check.
abstract class AbstractSearchRobot {
  Future<void> enterSearchText(String searchText);
  Future<void> deleteSearchPhrase();
  Future<void> backToPreviousScreen();

  /// Whether the "No Results" placeholder is shown.
  bool isNoResultVisible();

  /// Whether the search text field is present on screen.
  bool isSearchFieldVisible();
}
