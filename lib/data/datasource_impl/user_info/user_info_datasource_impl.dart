import 'package:matrix/matrix.dart';
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
  Future<UserInfoVisibility> getUserVisibility(String userId) async {
    try {
      return await _api.getUserVisibility(userId);
    } catch (error, stackTrace) {
      Logs().e('UserInfoDatasourceImpl::getUserVisibility', error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserInfoVisibility> updateUserInfoVisibility(
    String userId,
    UserInfoVisibilityRequest body,
  ) async {
    try {
      return await _api.updateUserVisibility(userId: userId, body: body);
    } catch (error, stackTrace) {
      Logs().e(
        'UserInfoDatasourceImpl::updateUserInfoVisibility',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
