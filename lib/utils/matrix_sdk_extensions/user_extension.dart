import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info_manager.dart';
import 'package:matrix/matrix.dart';

extension UserExtension on User {
  Future<String> calcUserDisplayName() async {
    try {
      final userInfo =
          await getIt.get<TwakeUserInfoManager>().getTwakeProfileFromUserId(
                client: room.client,
                userId: id,
              );
      return userInfo.displayName ?? calcDisplayname();
    } catch (e) {
      Logs().e(
        'UserExtension::calcUserDisplayName:: Error fetching user info for $id: $e',
      );
      return calcDisplayname();
    }
  }
}
