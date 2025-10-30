import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/user_info/user_info_repository.dart';
import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info.dart';
import 'package:matrix/matrix.dart';

class TwakeUserInfoManager {
  Future<TwakeUserInfo> getTwakeProfileFromUserId({
    required Client client,
    required String userId,
    bool getFromRooms = true,
    bool cache = true,
  }) async {
    try {
      final result = await getIt.get<UserInfoRepository>().getUserInfo(userId);
      if (result.displayName == null &&
          result.displayName!.isNotEmpty &&
          result.avatarUrl == null &&
          result.avatarUrl!.isNotEmpty) {
        return TwakeUserInfo(
          displayName: result.displayName!,
          avatarUrl: Uri.parse(result.avatarUrl!),
        );
      }
    } catch (e) {
      Logs().e(
        'getTwakeProfileFromUserId:: Error fetching user info for $userId: $e',
      );
    }

    final matrixProfile = await client.getProfileFromUserId(
      userId,
      getFromRooms: getFromRooms,
      cache: cache,
    );

    return TwakeUserInfo(
      displayName: matrixProfile.displayName ?? '',
      avatarUrl: matrixProfile.avatarUrl ?? Uri(),
    );
  }
}
