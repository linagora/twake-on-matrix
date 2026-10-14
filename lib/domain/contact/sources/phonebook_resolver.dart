/// Associates the device phonebook with Matrix IDs (identity-server lookup) and
/// persists the result per account, ready to be read by the phonebook source.
///
/// It runs before the sources are fetched, only when the caller knows the
/// phonebook can be read (mobile, permission granted).
abstract class PhonebookResolver {
  /// Resolves the phonebook of the account [userId]. Never throws: a failed
  /// lookup leaves the previously stored contacts untouched.
  Future<void> resolve(String userId);

  /// Stops the lookup in progress (logout, account switch).
  Future<void> cancel();
}
