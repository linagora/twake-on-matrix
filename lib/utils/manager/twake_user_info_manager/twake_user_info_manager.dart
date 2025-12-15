import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/domain/repository/user_info/user_info_repository.dart';
import 'package:matrix/matrix.dart';

class TwakeUserInfoManager {
  Future<UserInfo> getTwakeProfileFromUserId({
    required Client client,
    required String userId,
    bool getFromRooms = true,
    bool cache = true,
  }) async {
    final matrixProfile = await client.getProfileFromUserId(
      userId,
      getFromRooms: getFromRooms,
      cache: cache,
    );

    if (userId.isNotEmpty) {
      try {
        final result =
            await getIt.get<UserInfoRepository>().getUserInfo(userId);
        if (result.uid != null && result.uid!.isNotEmpty) {
          return UserInfo(
            uid: result.uid ?? matrixProfile.userId,
            displayName: result.displayName ?? matrixProfile.displayName ?? '',
            avatarUrl: result.avatarUrl != null && result.avatarUrl!.isNotEmpty
                ? result.avatarUrl!
                : (matrixProfile.avatarUrl?.toString() ?? ''),
          );
        }
      } catch (e) {
        Logs().e(
          'getTwakeProfileFromUserId:: Error fetching user info for $userId: $e',
        );
      }
    }

    return UserInfo(
      uid: matrixProfile.userId,
      displayName: matrixProfile.displayName ?? '',
      avatarUrl: matrixProfile.avatarUrl?.toString() ?? '',
    );
  }
}
