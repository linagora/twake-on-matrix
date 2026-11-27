abstract class CachedFilesDatasource {
  Future<void> deleteFilesCachedBefore(DateTime cutoff);
}
