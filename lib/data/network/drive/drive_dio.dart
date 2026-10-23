import 'package:dio/dio.dart';
import 'package:twake_chat/data/network/interceptor/drive_error_interceptor.dart';

/// Plain client for the Drive stack. Its only interceptor maps errors; nothing
/// logs request bodies, which carry tokens.
Dio createDriveDio() {
  const timeout = Duration(seconds: 10);
  return Dio(
    BaseOptions(
      connectTimeout: timeout,
      sendTimeout: timeout,
      receiveTimeout: timeout,
    ),
  )..interceptors.add(DriveErrorInterceptor());
}
