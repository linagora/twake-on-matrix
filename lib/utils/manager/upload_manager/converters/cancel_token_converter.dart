import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

class CancelTokenConverter implements JsonConverter<CancelToken, dynamic> {
  const CancelTokenConverter();

  @override
  CancelToken fromJson(dynamic _) => CancelToken();

  @override
  dynamic toJson(CancelToken _) => null;
}
