import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

class DioCacheOption {
  static const String _hiveBoxName = "twake_dio_cache_hive_store";
  static const Duration _maxStale = Duration(days: 7);

  late HiveCacheStore _hiveCacheStore;
  DioCacheOption._privateConstructor();

  static DioCacheOption get instance => _instance;

  static final DioCacheOption _instance = DioCacheOption._privateConstructor();

  factory DioCacheOption() {
    return _instance;
  }

  Future<String?> _getAppDirPath() async {
    if (kIsWeb) return null;
    final appDir = await getApplicationDocumentsDirectory();
    Logs().d('DioCacheOption::_getAppDirPath() appDirPath ${appDir.path}');
    return appDir.path;
  }

  Future<void> setUpDioHiveCache() async {
    Logs().d('DioCacheOption::_setUpDioHiveCache() Start setup DioHiveCache');
    final appDirPath = await _getAppDirPath();
    _hiveCacheStore = HiveCacheStore(
      appDirPath,
      hiveBoxName: _hiveBoxName,
    );
    Logs().d('DioCacheOption::_setUpDioHiveCache() DioHiveCache Ready');
  }

  CacheOptions getCacheOptions() {
    return CacheOptions(
      store: _hiveCacheStore,
      policy: CachePolicy.forceCache,
      maxStale: _maxStale,
      hitCacheOnErrorExcept: [401, 404],
      keyBuilder: (request) {
        return request.uri.toString();
      },
      allowPostMethod: false,
    );
  }
}
