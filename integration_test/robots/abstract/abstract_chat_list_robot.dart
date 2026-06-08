import '../twake_list_item_robot.dart';

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

  /// All chat rows currently rendered in the list.
  Future<List<TwakeListItemRobot>> getListOfChatGroup();

  /// Whether the chat list actually scrolls (content exceeds viewport).
  Future<bool> isListScrollable();

  /// Pins the chat titled [title] (no-op if already pinned).
  Future<void> pinChat(String title);

  /// Unpins the chat titled [title] (no-op if not pinned).
  Future<void> unpinChat(String title);

  /// Whether the chat titled [title] is currently pinned.
  Future<bool> isChatPinned(String title);
}
