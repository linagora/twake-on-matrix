import '../search_robot.dart';

/// Web-specific search robot.
///
/// On web there is no `BottomNavigationBar` — the app uses a
/// `NavigationRail` instead. `backToPreviousScreen` skips the
/// mobile-specific wait for the bottom bar.
class WebSearchRobot extends SearchRobot {
  WebSearchRobot(super.$);

  @override
  Future<void> backToPreviousScreen() async {
    await goBack();
    // No BottomNavigationBar on web — the rail is always visible.
  }
}
