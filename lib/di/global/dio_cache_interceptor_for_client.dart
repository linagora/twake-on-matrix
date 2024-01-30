import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:fluffychat/data/network/homeserver_endpoint.dart';
import 'package:fluffychat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

class DioCacheInterceptorForClient {
  static const _memCacheDioInterceptorForClientName =
      'memCacheDioInterceptorForClientName';

  final String userId;

  DioCacheInterceptorForClient(this.userId);

  String getInstanceNameForClient(String instanceName) {
    return '$instanceName-$userId';
  }

  void setup(GetIt get) {
    _bindInterceptor(get);
    _bindDioForHomeserver(get);
    _bindMethodSupportMemCache(get);
  }

  void _bindInterceptor(GetIt get) async {
    final instanceName =
        getInstanceNameForClient(_memCacheDioInterceptorForClientName);
    if (!get.isRegistered<MatrixDioCacheInterceptor>(
      instanceName: instanceName,
    )) {
      get.registerSingleton(
        MatrixDioCacheInterceptor(
          options: _getMemCacheOptionsForEachUserLoggedIn(),
        ),
        instanceName: instanceName,
      );
    }
  }

  CacheOptions _getMemCacheOptionsForEachUserLoggedIn() {
    return CacheOptions(
      store: getIt.get<MemCacheStore>(),
      policy: CachePolicy.forceCache,
      hitCacheOnErrorExcept: [404],
      maxStale: const Duration(days: 1),
      keyBuilder: (request) {
        final String accessToken = request.headers['Authorization'];
        final hashedAccessToken = sha256.convert(accessToken.codeUnits);
        Logs().d(
          'DioCacheOption::getMemCacheOptionsForEachClient() key - ${request.uri}$hashedAccessToken',
        );
        return '${request.uri}$hashedAccessToken';
      },
    );
  }

  void _bindDioForHomeserver(GetIt get) {
    final dio = get.get<Dio>(instanceName: NetworkDI.homeServerDioName);
    dio.interceptors.add(
      get.get<MatrixDioCacheInterceptor>(
        instanceName:
            getInstanceNameForClient(_memCacheDioInterceptorForClientName),
      ),
    );
  }

  void _bindMethodSupportMemCache(GetIt get) {
    final dioCacheCustomInterceptor = get.get<MatrixDioCacheInterceptor>(
      instanceName:
          getInstanceNameForClient(_memCacheDioInterceptorForClientName),
    );
    dioCacheCustomInterceptor.addUriSupportsCache([
      HomeserverEndpoint.configPath.generateHomeserverConfigEndpoint(),
    ]);
  }
}
