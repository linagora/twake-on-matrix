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
}
