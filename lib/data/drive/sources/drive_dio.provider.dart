import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drive_dio.provider.g.dart';

/// A client of its own: the shared one adds the Matrix bearer token to every
/// request, and neither the SSO nor Drive may receive it.
@Riverpod(keepAlive: true)
Dio driveDio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}
