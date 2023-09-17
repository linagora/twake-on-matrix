import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:matrix/matrix.dart';

class MatrixDioCacheInterceptor extends DioCacheInterceptor {
  MatrixDioCacheInterceptor({required super.options});

  final List<String> _uriSupportsCache = [];

  void addUriSupportsCache(List<String> uriSupportsCache) {
    Logs().d(
      'DioCacheCustomInterceptor::setPathSupportsCache() Add uriSupportsCache: $uriSupportsCache',
    );
    _uriSupportsCache.addAll(uriSupportsCache);
    Logs().d(
      'DioCacheCustomInterceptor::setPathSupportsCache() _pathSupportsCache: $_uriSupportsCache',
    );
  }

  bool _cacheSupported(String currentPath) {
    return _uriSupportsCache.any((path) => path.contains(currentPath));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_cacheSupported(options.path)) {
      handler.next(options);
      return;
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!_cacheSupported(response.requestOptions.path)) {
      handler.next(response);
      return;
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_cacheSupported(err.requestOptions.path)) {
      handler.next(err);
      return;
    }
    super.onError(err, handler);
  }
}
