import 'package:twake_chat/data/datasource/user_info/user_info_datasource.dart';
import 'package:twake_chat/data/network/user_info/user_info_api.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';

class UserInfoDatasourceImpl implements UserInfoDatasource {
  const UserInfoDatasourceImpl(this._api);

  final UserInfoApi _api;

  @override
  Future<UserInfo> getUserInfo(String userId) => _api.getUserInfo(userId);

  @override
  Future<UserInfoVisibility> getUserVisibility(String userId) =>
      _api.getUserVisibility(userId);

  @override
  Future<UserInfoVisibility> updateUserInfoVisibility(
    String userId,
    UserInfoVisibilityRequest body,
  ) => _api.updateUserVisibility(userId: userId, body: body);
}
