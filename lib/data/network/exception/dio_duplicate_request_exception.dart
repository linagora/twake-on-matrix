import 'package:dio/dio.dart';

class DioDuplicateRequestException extends DioException {
  DioDuplicateRequestException()
      : super(
          message: 'Download already in progress',
          requestOptions: RequestOptions(),
        );
}
