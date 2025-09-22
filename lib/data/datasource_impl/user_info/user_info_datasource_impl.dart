import 'package:fluffychat/data/datasource/user_info/user_info_datasource.dart';
import 'package:fluffychat/data/network/user_info/user_info_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';

class UserInfoDatasourceImpl implements UserInfoDatasource {
  const UserInfoDatasourceImpl();

  @override
  Future<UserInfo> getUserInfo(String userId) {
    return getIt.get<UserInfoApi>().getUserInfo(userId);
  }
}
