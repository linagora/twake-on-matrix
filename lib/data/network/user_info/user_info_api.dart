import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:twake_chat/data/network/tom_endpoint.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';

class UserInfoApi {
  const UserInfoApi(this._client, this._memCacheInterceptor);

  final DioClient _client;
  final MatrixDioCacheInterceptor _memCacheInterceptor;

  Future<UserInfo> getUserInfo(String userId) async {
    final uri = TomEndpoint.userInfoServicePath.generateTomUserInfoEndpoint(
      userId,
    );
    _memCacheInterceptor.addUriSupportsCache([uri]);
    final response = await _client.get(uri);
    return UserInfo.fromJson(response);
  }

  Future<UserInfoVisibility> getUserVisibility(String userId) async {
    final uri = TomEndpoint.userInfoServicePath.userInfoVisibilityServicePath(
      userId,
    );
    final response = await _client.get(uri);
    return UserInfoVisibility.fromJson(response);
  }

  Future<UserInfoVisibility> updateUserVisibility({
    required String userId,
    required UserInfoVisibilityRequest body,
  }) async {
    final uri = TomEndpoint.userInfoServicePath.userInfoVisibilityServicePath(
      userId,
    );
    final response = await _client.postToGetBody(uri, data: body.toJson());
    return UserInfoVisibility.fromJson(response);
  }
}
