import 'package:twake_chat/data/datasource/user_info/user_info_datasource.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

class UserInfoRepositoryImpl implements UserInfoRepository {
  const UserInfoRepositoryImpl(this._datasource);

  final UserInfoDatasource _datasource;

  @override
  Future<UserInfo> getUserInfo(String userId) =>
      _datasource.getUserInfo(userId);

  @override
  Future<UserInfoVisibility> getUserVisibility(String userId) =>
      _datasource.getUserVisibility(userId);

  @override
  Future<UserInfoVisibility> updateUserInfoVisibility(
    String userId,
    UserInfoVisibilityRequest body,
  ) => _datasource.updateUserInfoVisibility(userId, body);
}
