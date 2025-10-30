import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:fluffychat/data/network/tom_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';

class UserInfoApi {
  const UserInfoApi();

  Future<UserInfo> getUserInfo(String userId) async {
    final uri =
        TomEndpoint.userInfoServicePath.generateTomUserInfoEndpoint(userId);

    final dioCacheCustomInterceptor = getIt.get<MatrixDioCacheInterceptor>(
      instanceName: NetworkDI.memCacheDioInterceptorName,
    );

    dioCacheCustomInterceptor.addUriSupportsCache([
      uri,
    ]);

    final client = getIt.get<DioClient>(
      instanceName: NetworkDI.tomDioClientName,
    );

    final response = await client.get(uri);
    return UserInfo.fromJson(response);
  }
}
