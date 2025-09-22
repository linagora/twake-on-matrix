import 'package:fluffychat/domain/model/user_info/user_info.dart';

abstract class UserInfoDatasource {
  Future<UserInfo> getUserInfo(String userId);
}
