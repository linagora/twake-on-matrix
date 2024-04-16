import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

class DioDuplicateDownloadException extends DioException with EquatableMixin {
  DioDuplicateDownloadException({required RequestOptions requestOptions})
      : super(
          message: 'Download already in progress',
          requestOptions: requestOptions,
          type: DioExceptionType.unknown,
        );

  @override
  List<Object?> get props => [message, requestOptions, type];
}
