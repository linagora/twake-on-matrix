import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:twake_chat/data/network/user_info/user_info_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';

part 'user_info_api.provider.g.dart';

@Riverpod(keepAlive: true)
UserInfoApi userInfoApi(Ref ref) => UserInfoApi(
  // TODO: [transitional] Bridge: NetworkDI's ToM DioClient, shared with the GetIt ToM APIs (base url set by MatrixState).
  getIt.get<DioClient>(instanceName: NetworkDI.tomDioClientName),
  // TODO: [transitional] Bridge: NetworkDI's memory cache, shared with the GetIt Dios and matrix.dart's user_info lookup.
  getIt.get<MatrixDioCacheInterceptor>(
    instanceName: NetworkDI.memCacheDioInterceptorName,
  ),
);
