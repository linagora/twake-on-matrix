import 'package:dio/dio.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';

class WorkplaceFailures {
  const WorkplaceFailures();

  bool isExchangeFailure(DioException e) =>
      e.requestOptions.uri.path.endsWith('/auth/token_exchange');

  bool isChatAppMissing(DioException e) =>
      e.response?.statusCode == 400 &&
      isExchangeFailure(e) &&
      '${e.response?.data}'.toLowerCase().contains('not installed');

  DriveException? connectionFailureOf(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const DriveTimedOut(),
    DioExceptionType.connectionError => const DriveOffline(),
    DioExceptionType.badCertificate ||
    DioExceptionType.badResponse ||
    DioExceptionType.cancel ||
    DioExceptionType.unknown => null,
  };
}
