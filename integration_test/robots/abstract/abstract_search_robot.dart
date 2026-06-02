/// Platform-agnostic contract for the search screen.
///
/// `backToPreviousScreen` already diverges: mobile waits for
/// `BottomNavigationBar`, web skips that check.
abstract class AbstractSearchRobot {
  Future<void> enterSearchText(String searchText);
  Future<void> deleteSearchPhrase();
  Future<void> backToPreviousScreen();
}
