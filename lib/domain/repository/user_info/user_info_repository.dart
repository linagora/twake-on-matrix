import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';

abstract class UserInfoRepository {
  Future<UserInfo> getUserInfo(String userId);

  Future<UserInfoVisibility> getUserVisibility(String userId);
}
