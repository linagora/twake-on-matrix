/// Platform-agnostic contract for the per-message action menu.
///
/// The menu is opened very differently per platform:
/// - Mobile: long-press the message bubble → `PullDownMenu` overlay.
/// - Web/desktop: hover the message bubble → horizontal action bar of
///   `TwakeIconButton`s (reaction / reply / forward / more). The "more"
///   overflow reuses the same `PullDownMenu` as mobile, but first-class
///   actions (reply, forward) are tapped directly from the bar.
///
/// Methods are added here as each `chat/*` test is migrated and validated
/// web-green. Today only the forward path is covered (PR 9b).
abstract class AbstractMessageMenuRobot {
  /// Opens the action menu for the bubble containing [message], triggers the
  /// Forward action, and waits until the Forward screen (`ForwardView`) is on
  /// screen.
  Future<void> openForward(String message);
}
