import 'package:dio/dio.dart';
import 'package:twake_chat/data/network/drive_endpoint.dart';
import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';

/// Puts a [DriveException] in `DioException.error`; read it with
/// [runDriveRequest].
///
/// Only credential errors are told apart (the caller may fetch a fresh token
/// and retry); every other failure is one generic exception.
class DriveErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = _mapToDriveException(err);
    handler.next(mapped == null ? err : err.copyWith(error: mapped));
  }

  DriveException? _mapToDriveException(DioException err) {
    if (err.type == DioExceptionType.cancel ||
        err.type == DioExceptionType.badCertificate) {
      return null;
    }
    final status = err.response?.statusCode;
    final isTokenExchange = err.requestOptions.uri.path.endsWith(
      DriveEndpoint.tokenExchangeServicePath.path,
    );
    return switch (status) {
      401 || 403 => DriveAuthRejectedException(status!),
      400 when isTokenExchange => DriveAuthRejectedException(status!),
      _ => DriveRequestFailedException(status),
    };
  }
}

Future<T> runDriveRequest<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    final mapped = e.error;
    if (mapped is DriveException) throw mapped;
    rethrow;
  }
}
