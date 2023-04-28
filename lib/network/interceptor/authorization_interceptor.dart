import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AuthorizationInterceptor extends InterceptorsWrapper {
  AuthorizationInterceptor();

  String? _accessToken;

  set accessToken(String? accessToken) {
    _accessToken = accessToken;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[HttpHeaders.authorizationHeader] = _bearerToken;
    debugPrint('accessToken: $_bearerToken');
    super.onRequest(options, handler);
  }

  String get _bearerToken => 'Bearer $_accessToken';
}