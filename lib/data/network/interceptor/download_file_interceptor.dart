import 'package:dio/dio.dart';
import 'package:fluffychat/data/network/exception/dio_duplicate_download_exception.dart';
import 'package:matrix/matrix.dart';

class DownloadFileInterceptor extends InterceptorsWrapper {
  DownloadFileInterceptor();

  final _currentDownloads = <String>{};

  static const downloadPath = '_matrix/media/v3/download/';

  Set<String> get currentDownloads => _currentDownloads;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Logs().d('DownloadFileInterceptor::onRequest: ${options.path}');
    if (!options.path.contains(downloadPath)) {
      super.onRequest(options, handler);
      return;
    }
    if (isAlreadyDownloading(options.path)) {
      handler.reject(
        DioDuplicateDownloadException(requestOptions: options),
      );
      return;
    }
    _currentDownloads.add(options.path);
    super.onRequest(options, handler);
  }

  bool isAlreadyDownloading(String path) {
    return path.contains(downloadPath) && _currentDownloads.contains(path);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _currentDownloads
        .removeWhere((request) => request == err.requestOptions.path);
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _currentDownloads
        .removeWhere((request) => request == response.requestOptions.path);
    super.onResponse(response, handler);
  }
}
