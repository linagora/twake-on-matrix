import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:matrix/matrix.dart';

extension UserInfoExtension on UserInfo {
  Profile toMatrixProfile() {
    return Profile(
      userId: uid ?? '',
      displayName: displayName != null ? displayName! : '',
      avatarUrl: avatarUrl != null && avatarUrl!.isNotEmpty
          ? Uri.parse(avatarUrl!)
          : null,
    );
  }
}
