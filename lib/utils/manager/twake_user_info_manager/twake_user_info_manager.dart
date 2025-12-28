import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/domain/repository/user_info/user_info_repository.dart';
import 'package:matrix/matrix.dart';

class TwakeUserInfoManager {
  final UserInfoRepository userInfoRepository;
  final Map<String, UserInfo> _userInfoCache = {};

  TwakeUserInfoManager({
    required this.userInfoRepository,
  });

  Future<UserInfo> getTwakeProfileFromUserId({
    required Client client,
    required String userId,
    bool getFromRooms = true,
    bool cache = true,
  }) async {
    // Return cached result if available and caching is enabled
    if (cache && _userInfoCache.containsKey(userId)) {
      Logs().v(
        'getTwakeProfileFromUserId:: Returning cached user info for $userId',
      );
      return _userInfoCache[userId]!;
    }

    final matrixProfile = await client.getProfileFromUserId(
      userId,
      getFromRooms: getFromRooms,
      cache: cache,
    );

    UserInfo? userInfo;

    if (userId.isEmpty) {
      userInfo = UserInfo(
        uid: matrixProfile.userId,
        displayName: matrixProfile.displayName ?? '',
        avatarUrl: matrixProfile.avatarUrl?.toString() ?? '',
      );
    } else {
      try {
        final result = await userInfoRepository.getUserInfo(userId);
        userInfo = UserInfo(
          uid: result.uid ?? matrixProfile.userId,
          displayName: result.displayName ?? matrixProfile.displayName ?? '',
          avatarUrl: result.avatarUrl != null && result.avatarUrl!.isNotEmpty
              ? result.avatarUrl!
              : (matrixProfile.avatarUrl?.toString() ?? ''),
        );
      } catch (e) {
        Logs().e(
          'getTwakeProfileFromUserId:: Error fetching user info for $userId: $e',
        );
        // Fallback to Matrix profile when API fails
        userInfo = UserInfo(
          uid: matrixProfile.userId,
          displayName: matrixProfile.displayName ?? '',
          avatarUrl: matrixProfile.avatarUrl?.toString() ?? '',
        );
      }
    }

    // Store in cache if caching is enabled
    if (cache) {
      _userInfoCache[userId] = userInfo;
      Logs().v(
        'getTwakeProfileFromUserId:: Cached user info for $userId. Cache size: ${_userInfoCache.length}',
      );
    }

    return userInfo;
  }

  /// Clears the user info cache
  void clearCache() {
    _userInfoCache.clear();
  }

  /// Removes a specific user from the cache
  void removeFromCache(String userId) {
    _userInfoCache.remove(userId);
  }
}
