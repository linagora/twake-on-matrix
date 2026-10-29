import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/interceptor/authorization_interceptor.provider.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';

part 'dio_client.provider.g.dart';

// No cache interceptor: no route of this client is cacheable.
@Riverpod(keepAlive: true)
DioClient tomDioClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      headers: {
        HttpHeaders.acceptHeader: Headers.jsonContentType,
        HttpHeaders.contentTypeHeader: Headers.jsonContentType,
      },
    ),
  );
  dio.interceptors.addAll([
    ref.watch(tomServerUrlInterceptorProvider),
    ref.watch(authorizationInterceptorProvider),
    if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
  ]);
  ref.onDispose(dio.close);
  return DioClient(dio);
}

// TODO: [transitional] Shared with AddressBookApi, TomContactAPI, InvitationAPI, RecoveryWordsAPI, UserInfoRepository (GetIt).
@Riverpod(keepAlive: true)
DioClient legacyTomDioClient(Ref ref) =>
    getIt.get<DioClient>(instanceName: NetworkDI.tomDioClientName);
