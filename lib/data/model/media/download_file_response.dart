import 'package:dio/dio.dart';

class DownloadFileResponse extends Response<dynamic> {
  final String savePath;

  final ProgressCallback? onReceiveProgress;

  DownloadFileResponse({
    super.statusCode,
    super.statusMessage,
    super.data,
    super.extra,
    super.headers,
    super.isRedirect,
    super.redirects,
    required super.requestOptions,
    required this.savePath,
    this.onReceiveProgress,
  });
}
