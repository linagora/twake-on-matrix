import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DynamicUrlInterceptors extends InterceptorsWrapper {
  final ValueNotifier<String?> _baseUrl = ValueNotifier(null);

  void changeBaseUrl(String? url) {
    _baseUrl.value = url;
  }

  String? get baseUrl => _baseUrl.value;

  ValueListenable<String?> get baseUrlListenable => _baseUrl;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final baseUrl = _baseUrl.value;
    if (baseUrl != null) {
      options.baseUrl = baseUrl;
    }
    super.onRequest(options, handler);
  }
}
