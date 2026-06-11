import 'package:patrol/patrol.dart';

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

  /// Types [message] into the composer and taps the send button.
  Future<void> sendMessage(String message);

  /// Resolves the finder for a message bubble containing [text].
  ///
  /// May resolve through different message-widget types on web vs mobile.
  Future<PatrolFinder> getText(String text);

  Future<void> clickOnBackIcon();
  Future<void> confirmAccessMedia();
}
