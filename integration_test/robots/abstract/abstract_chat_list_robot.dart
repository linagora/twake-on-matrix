/// Platform-agnostic contract for the chat-list screen.
///
/// Covers opening individual chats, search, and querying list state.
/// Methods that return platform-specific finders (e.g. `PatrolFinder`)
/// are left in the concrete class — only action/query methods that
/// scenarios call appear here.
abstract class AbstractChatListRobot {
  Future<void> openChatGroupByIndex(int index);
  Future<void> openSearchScreen();
  Future<void> clickOnPenIcon();
  Future<void> clickOnPinIcon();
  Future<void> clickOnUnPinIcon();
  int getUnreadMessage(String title);
  Future<int> getChatRoomCounts();
}
