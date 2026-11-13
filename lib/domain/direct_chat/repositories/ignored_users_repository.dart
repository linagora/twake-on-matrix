abstract class IgnoredUsersRepository {
  /// Emits whether [userId] is in the ignore list now, then on every change.
  Stream<bool> watchIsIgnored(String userId);
}
