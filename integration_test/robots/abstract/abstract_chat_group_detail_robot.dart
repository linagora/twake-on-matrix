/// Platform-agnostic contract for the chat-room detail screen.
///
/// Divergences: `getText` may resolve through different message-widget
/// types on web vs mobile; back-navigation may use router vs AppBar
/// icon depending on layout width.
abstract class AbstractChatGroupDetailRobot {
  Future<bool> isVisible();
  String? getTitle();
  String getTotalMemberLabel();
  Future<void> tapOnChatBarTitle();
  Future<void> tapOnChatBarTitleForDM();
  Future<void> inputMessage(String message);
  Future<void> clickOnBackIcon();
  Future<void> confirmAccessMedia();
}
