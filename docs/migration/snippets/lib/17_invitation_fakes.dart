// test/features/invitation/fakes/

import '04_invitation_api_datasource.dart';
import '05_invitation_local_datasource.dart';

class FakeInvitationApiDataSource implements InvitationApiDataSource {
  String? linkToReturn;
  Exception? errorToThrow;

  @override
  Future<String> generateLink(String roomId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return linkToReturn ?? 'https://fake-link.com';
  }

  @override
  Future<void> sendInvitation({
    required String roomId,
    required String targetUserId,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
  }
}

class FakeInvitationLocalDataSource implements InvitationLocalDataSource {
  final _cache = <String, String>{};

  @override
  Future<String?> getCachedLink(String roomId) async => _cache[roomId];

  @override
  Future<void> cacheLink(String roomId, String url) async =>
      _cache[roomId] = url;

  @override
  Future<void> clearCache(String roomId) async => _cache.remove(roomId);
}
