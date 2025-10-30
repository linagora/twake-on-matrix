import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info.dart';
import 'package:matrix/matrix.dart';

extension TwakeUserInfoExtension on TwakeUserInfo {
  Profile toMatrixProfile() {
    return Profile(
      userId: matrixId,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
