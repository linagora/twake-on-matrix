import 'package:flutter_test/flutter_test.dart';

/// Platform-agnostic contract for the per-message action menu.
///
/// The menu is opened very differently per platform:
/// - Mobile: long-press the message bubble → `PullDownMenu` overlay.
/// - Web/desktop: hover the message bubble → horizontal action bar of
///   `TwakeIconButton`s (reaction / reply / forward / more). When collapsed,
///   "more" opens a context-menu dialog with `ContextMenuActionItemWidget`s;
///   first-class actions (reply, forward) are tapped directly from the bar.
///
/// Methods are added here as each `chat/*` test is migrated and validated
/// web-green.
abstract class AbstractMessageMenuRobot {
  /// Opens the action menu for the bubble containing [message], triggers the
  /// Forward action, and waits until the Forward screen (`ForwardView`) is on
  /// screen.
  Future<void> openForward(String message);

  /// Same as [openForward], for the newest message bubble containing
  /// [content].
  Future<void> openForwardOnLast(Finder content);

  /// Opens the action menu for [message] and taps Reply, leaving the composer
  /// in reply mode (the caller then sends the reply).
  Future<void> openReply(String message);

  /// Opens the action menu for [message], taps Delete, and confirms the
  /// deletion in the follow-up dialog (a native dialog on mobile, a Flutter
  /// `AlertDialog` on web).
  Future<void> openDelete(String message);

  /// Opens the action menu for [message] and taps Edit, leaving the composer
  /// in edit mode (the caller then types and sends the new text).
  Future<void> openEdit(String message);

  /// Opens the action menu for [message] and taps Select, entering the
  /// multi-select mode.
  Future<void> openSelect(String message);

  /// Selects [message] and opens its info from the selection-mode app bar
  /// ("More" → "Message info"), leaving the `EventInfoDialog` on screen. The
  /// caller asserts the dialog contents and closes it.
  Future<void> openMessageInfo(String message);

  /// Opens the action menu for [message] and taps [emoji] in the quick
  /// reaction row. Tapping the emoji already reacted removes the reaction.
  Future<void> reactWithQuickEmoji(String message, String emoji);

  /// Opens the action menu for [message] and expands the full emoji picker.
  Future<void> openFullEmojiPicker(String message);
}
