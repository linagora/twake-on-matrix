import '../twake_list_item_robot.dart';

/// Platform-agnostic contract for the chat-list screen.
///
/// Covers opening individual chats, search, and querying list state.
/// Methods that return platform-specific finders (e.g. `PatrolFinder`)
/// are left in the concrete class — only action/query methods that
/// scenarios call appear here.
abstract class AbstractChatListRobot {
  Future<void> openChatGroupByIndex(int index);

  /// Opens the chat row whose title matches [title] from the (unfiltered) list.
  /// Avoids the search screen so callers return to the same list afterwards.
  Future<void> openChatByTitle(String title);

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

  /// Opens the new-chat flow, searches for [account] and starts a direct
  /// message with the first match. Settles on the chat or draft-chat screen.
  ///
  /// Returns `false` when the search yields no account row (e.g. an
  /// unresolvable remote address on web), so callers can branch without a
  /// timeout.
  Future<bool> createDirectMessage(String account);

  /// Opens the new-group flow, adds the member(s) matched by [memberSearchKey],
  /// names the group [name] and confirms. Settles on the new group's chat view.
  Future<void> createGroupChat(String name, String memberSearchKey);
}
