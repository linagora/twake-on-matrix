import 'package:twake_chat/data/datasource/user_info/user_info_datasource.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

class UserInfoRepositoryImpl implements UserInfoRepository {
  const UserInfoRepositoryImpl();

  @override
  Future<UserInfo> getUserInfo(String userId) {
    return getIt.get<UserInfoDatasource>().getUserInfo(userId);
  }

  @override
  Future<UserInfoVisibility> getUserVisibility(String userId) {
    return getIt.get<UserInfoDatasource>().getUserVisibility(userId);
  }

  @override
  Future<UserInfoVisibility> updateUserInfoVisibility(
    String userId,
    UserInfoVisibilityRequest body,
  ) {
    return getIt.get<UserInfoDatasource>().updateUserInfoVisibility(
      userId,
      body,
    );
  }
}
