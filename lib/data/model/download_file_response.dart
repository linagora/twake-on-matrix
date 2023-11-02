import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

class DownloadFileResponse extends Response<dynamic> with EquatableMixin {
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

  @override
  List<Object?> get props => [
        statusCode,
        statusMessage,
        data,
        extra,
        headers,
        isRedirect,
        requestOptions,
        savePath,
        onReceiveProgress,
        requestOptions,
      ];
}
