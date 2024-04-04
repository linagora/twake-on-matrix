import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:fluffychat/data/network/status_error_code.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:matrix/matrix.dart';

class DioCacheOption {
  static const String _hiveBoxName = "twake_dio_cache_hive_store";
  static const Duration _maxStale = Duration(days: 3);

  late HiveCacheStore _hiveCacheStore;

  DioCacheOption._privateConstructor();

  static DioCacheOption get instance => _instance;

  static final DioCacheOption _instance = DioCacheOption._privateConstructor();

  factory DioCacheOption() {
    return _instance;
  }

  Future<void> setUpDioHiveCache() async {
    Logs().d('DioCacheOption::_setUpDioHiveCache() Start setup DioHiveCache');
    _hiveCacheStore = HiveCacheStore(
      null,
      hiveBoxName: _hiveBoxName,
    );
    Logs().d('DioCacheOption::_setUpDioHiveCache() DioHiveCache Ready');
  }

  CacheOptions getHiveCacheOptions() {
    return CacheOptions(
      store: _hiveCacheStore,
      policy: CachePolicy.forceCache,
      maxStale: _maxStale,
      hitCacheOnErrorExcept: [404],
      keyBuilder: (request) {
        Logs().d(
          'DioCacheOption::getCacheOptions() Request URI - ${request.uri}',
        );
        return request.uri.toString();
      },
    );
  }

  CacheOptions getMemCacheOptions() {
    return CacheOptions(
      store: getIt.get<MemCacheStore>(),
      policy: CachePolicy.forceCache,
      hitCacheOnErrorExcept: HttpResponseStatusCode.errorCodes,
      keyBuilder: (request) {
        Logs().d(
          'DioCacheOption::getMemCacheOptions() Request URI - ${request.uri}',
        );
        return request.uri.toString();
      },
    );
  }
}
