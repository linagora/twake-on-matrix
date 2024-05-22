import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

class DioDuplicateDownloadException extends DioException with EquatableMixin {
  DioDuplicateDownloadException({required super.requestOptions})
      : super(
          message: 'Download already in progress',
          type: DioExceptionType.unknown,
        );

  @override
  List<Object?> get props => [message, requestOptions, type];
}
