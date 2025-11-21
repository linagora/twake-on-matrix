import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility_request.dart';

abstract class UserInfoDatasource {
  Future<UserInfo> getUserInfo(String userId);

  Future<UserInfoVisibility> getUserVisibility(String userId);

  Future<UserInfoVisibility> updateUserInfoVisibility(
    String userId,
    UserInfoVisibilityRequest userInfoVisibility,
  );
}
