import 'dart:async';

import 'package:dio/dio.dart';
import 'package:twake_chat/data/network/exception/dio_duplicate_download_exception.dart';
import 'package:matrix/matrix.dart';

class DownloadFileInterceptor extends InterceptorsWrapper {
  DownloadFileInterceptor();

  final _currentDownloads = <String, Completer<void>>{};

  static const downloadPath = '_matrix/media/v3/download/';

  Set<String> get currentDownloads => _currentDownloads.keys.toSet();

  Future<void> whenDone(String path) =>
      _currentDownloads[path]?.future ?? Future.value();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Logs().d('DownloadFileInterceptor::onRequest: ${options.path}');
    if (!options.path.contains(downloadPath)) {
      super.onRequest(options, handler);
      return;
    }
    if (isAlreadyDownloading(options.path)) {
      handler.reject(DioDuplicateDownloadException(requestOptions: options));
      return;
    }
    _currentDownloads[options.path] = Completer<void>();
    super.onRequest(options, handler);
  }

  bool isAlreadyDownloading(String path) {
    return path.contains(downloadPath) && _currentDownloads.containsKey(path);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _currentDownloads.remove(err.requestOptions.path)?.complete();
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _currentDownloads.remove(response.requestOptions.path)?.complete();
    super.onResponse(response, handler);
  }
}
