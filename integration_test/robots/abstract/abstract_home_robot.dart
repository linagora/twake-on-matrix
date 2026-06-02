/// Platform-agnostic contract for bottom-navigation between the three
/// main tabs (contacts, chats, settings).
///
/// Concrete implementations resolve platform-specific widget finders
/// (e.g. Key-based on mobile vs icon-based on web when
/// `AdaptiveScaffold.toRailDestination` drops the widget key).
abstract class AbstractHomeRobot {
  Future<void> gotoContactListScreen();
  Future<void> gotoChatListScreen();
  Future<void> gotoSettingScreen();
}
