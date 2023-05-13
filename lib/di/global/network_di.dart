import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/interceptor/tom_authorization_interceptor.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class NetworkDI extends BaseDI {

  static const acceptHeaderDefault = 'application/json';
  static const contentTypeHeaderDefault = 'application/json';

  @override
  void setUp(GetIt get) {
    _bindBaseOption(get);
    _bindDio(get);
    _bindDioClient(get);
  }

  void _bindBaseOption(GetIt get) {
    final headers = <String, dynamic>{
      HttpHeaders.acceptHeader: acceptHeaderDefault,
      HttpHeaders.contentTypeHeader: contentTypeHeaderDefault
    };

    get.registerLazySingleton<BaseOptions>(() => BaseOptions(headers: headers));
  }

  void _bindDio(GetIt get) {
    get.registerSingleton<ToMAuthorizationInterceptor>(ToMAuthorizationInterceptor());
    final dio = Dio(get.get<BaseOptions>());
    dio.interceptors.add(get.get<ToMAuthorizationInterceptor>());
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
    get.registerLazySingleton<Dio>(() => dio);
  }

  void _bindDioClient(GetIt get) {
    get.registerLazySingleton(() => DioClient(get.get<Dio>()));
  }

  @override
  String get scopeName => 'networkScope';
}