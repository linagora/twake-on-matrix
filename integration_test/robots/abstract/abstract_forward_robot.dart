/// Platform-agnostic contract for the Forward screen (`ForwardView`).
///
/// Implemented by `ForwardRobot` (shared mobile/web — the room search,
/// selection and send button already branch internally on layout). The
/// factory returns it so scenarios never reference a concrete class.
abstract class AbstractForwardRobot {
  /// Opens the search bar (if needed) and types [query].
  Future<void> searchRoom(String query);

  /// Clears the search field to restore the full room list.
  Future<void> clearSearch();

  /// Taps the row whose title contains [roomName] to toggle its selection.
  Future<void> selectChatByName(String roomName);

  /// Taps the send / forward button (works on both mobile and web layout).
  Future<void> tapSendButton();

  /// Waits until the row for [roomName] is visible in the list.
  Future<void> verifyRoomInList(String roomName);

  /// Asserts the checkbox for [roomName] is checked.
  void verifyRoomSelected(String roomName);

  /// Asserts the checkbox for [roomName] is unchecked.
  void verifyRoomNotSelected(String roomName);

  /// Waits until `ForwardView` is on screen.
  Future<void> verifyForwardScreenVisible();

  /// Waits until the receiver room [roomName] is opened (its `ChatView`).
  Future<void> verifyOpenedRoom(String roomName);

  /// Waits for the source `ChatView` then asserts `ForwardView` is gone.
  Future<void> verifyForwardViewDismissed();

  /// Waits for and asserts the multi-forward success snackbar for [count] rooms.
  Future<void> verifyMultiForwardSuccessSnackbar(int count);
}
