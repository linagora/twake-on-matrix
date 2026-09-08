/// Persists the SSSS recovery key on-device so a later bootstrap run can
/// prefill or auto-unlock without asking the user to re-enter it.
abstract class RecoveryKeyStorageRepository {
  /// Stores [recoveryKey] for [userId], overwriting any previous value.
  Future<void> write({required String userId, required String recoveryKey});

  /// Returns the cached recovery key for [userId], or `null` if none.
  Future<String?> read({required String userId});
}
