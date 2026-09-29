import 'package:dio/dio.dart';

class DioDuplicateDownloadException extends DioException {
  DioDuplicateDownloadException({required super.requestOptions})
    : super(
        message: 'Download already in progress',
        type: DioExceptionType.unknown,
      );
}
