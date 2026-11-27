abstract class CachedFilesRepository {
  /// Downloaded and decrypted files only, never the ones saved by the user.
  Future<void> deleteFilesCachedBefore(DateTime cutoff);
}
