import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:matrix/matrix.dart';

extension UserInfoExtension on UserInfo {
  Profile toMatrixProfile() {
    Uri? parsedAvatarUrl;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      try {
        parsedAvatarUrl = Uri.parse(avatarUrl!);
      } catch (e) {
        Logs().w('UserInfoExtension: Invalid avatar URL: $avatarUrl', e);
        parsedAvatarUrl = null;
      }
    }
    return Profile(
      userId: uid ?? '',
      displayName: displayName != null ? displayName! : '',
      avatarUrl: parsedAvatarUrl,
    );
  }
}
