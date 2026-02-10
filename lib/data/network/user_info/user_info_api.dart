import 'package:dio/dio.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:fluffychat/data/network/tom_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility_request.dart';

class UserInfoApi {
  const UserInfoApi();

  Future<UserInfo> getUserInfo(String userId) async {
    final client = getIt.get<DioClient>(
      instanceName: NetworkDI.tomDioClientName,
    );

    final uri = TomEndpoint.userInfoServicePath.generateTomUserInfoEndpoint(
      userId,
    );

    final dioCacheCustomInterceptor = getIt.get<MatrixDioCacheInterceptor>(
      instanceName: NetworkDI.memCacheDioInterceptorName,
    );

    dioCacheCustomInterceptor.addUriSupportsCache([uri]);

    final response = await client.get(uri).onError((error, stackTrace) {
      if (error is DioException) {
        throw DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: error.error,
          stackTrace: error.stackTrace,
        );
      } else {
        throw Exception(error);
      }
    });
    return UserInfo.fromJson(response);
  }

  Future<UserInfoVisibility> getUserVisibility(String userId) async {
    final client = getIt.get<DioClient>(
      instanceName: NetworkDI.tomDioClientName,
    );

    final uri = TomEndpoint.userInfoServicePath.userInfoVisibilityServicePath(
      userId,
    );

    final response = await client.get(uri).onError((error, stackTrace) {
      if (error is DioException) {
        throw DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: error.error,
          stackTrace: error.stackTrace,
        );
      } else {
        throw Exception(error);
      }
    });
    return UserInfoVisibility.fromJson(response);
  }

  Future<UserInfoVisibility> updateUserVisibility({
    required String userId,
    required UserInfoVisibilityRequest body,
  }) async {
    final client = getIt.get<DioClient>(
      instanceName: NetworkDI.tomDioClientName,
    );

    final uri = TomEndpoint.userInfoServicePath.userInfoVisibilityServicePath(
      userId,
    );

    final response = await client
        .postToGetBody(uri, data: body.toJson())
        .onError((error, stackTrace) {
          if (error is DioException) {
            throw DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: error.error,
              stackTrace: error.stackTrace,
            );
          } else {
            throw Exception(error);
          }
        });
    return UserInfoVisibility.fromJson(response);
  }
}
