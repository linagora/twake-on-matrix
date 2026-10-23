import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

Map<String, dynamic> asJsonObject(Object? data) {
  final decoded = data is String ? jsonDecode(data) : data;
  if (decoded is Map<String, dynamic>) return decoded;
  throw FormatException(
    'Expected a JSON object from Drive, got ${decoded.runtimeType}',
  );
}

/// Runs a generated `fromJson`; any shape mismatch becomes a [FormatException].
T parseDriveJson<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) fromJson,
) {
  try {
    return fromJson(json);
  } on CheckedFromJsonException {
    throw const FormatException('Unexpected Drive response');
  } on TypeError {
    throw const FormatException('Unexpected Drive response');
  }
}
