// data/datasources/invitation_local_datasource.dart

abstract class InvitationLocalDataSource {
  Future<String?> getCachedLink(String roomId);
  Future<void> cacheLink(String roomId, String url);
  Future<void> clearCache(String roomId);
}
