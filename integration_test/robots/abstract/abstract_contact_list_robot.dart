import '../twake_list_item_robot.dart';

/// Platform-agnostic contract for the contacts-list screen.
///
/// `TwakeListItemRobot` wraps a single `TwakeListItem` and is
/// platform-independent today, so it is returned directly from the contract.
abstract class AbstractContactListRobot {
  /// All contact rows currently rendered in the list.
  Future<List<TwakeListItemRobot>> getListOfContact();

  /// Whether the contact list actually scrolls (content exceeds viewport).
  Future<bool> isListScrollable();
}
