/// Platform-agnostic contract for the room-search view.
///
/// Implemented by `SearchViewRobot` (shared mobile/web for now); the
/// factory returns the platform-appropriate instance so scenarios never
/// reference a concrete class.
abstract class AbstractSearchViewRobot {
  /// Searches for [roomName] and opens the first matching room.
  ///
  /// Returns `false` when no room matches, so the scenario can decide
  /// whether that is a failure or an expected platform divergence.
  Future<bool> searchAndOpenRoom(String roomName);
}
