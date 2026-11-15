import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:twake_chat/data/datasource/call/call_token_datasource.dart';
import 'package:twake_chat/data/model/call/sfu_token_request.dart';
import 'package:twake_chat/data/model/call/sfu_token_response.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

/// The MatrixRTC token service of the well-known (MSC4195).
class SfuCallTokenDatasourceImpl implements CallTokenDatasource {
  const SfuCallTokenDatasourceImpl(this._httpClient);

  static const _timeout = Duration(seconds: 20);

  final http.Client _httpClient;

  @visibleForTesting
  static CallServer parseServer(http.Response response) {
    if (response.statusCode ~/ 100 != 2) {
      throw CallTokenFailedException(cause: 'HTTP ${response.statusCode}');
    }
    final Object? json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const CallTokenFailedException(cause: 'Unexpected body');
    }
    final token = SfuTokenResponse.fromJson(json);
    final url = token.url;
    final jwt = token.jwt;
    if (url == null || jwt == null) {
      throw const CallTokenFailedException(cause: 'No url or jwt');
    }
    return CallServer(url: url, token: jwt);
  }

  @override
  Future<CallServer> fetchServer(
    String serviceUrl,
    SfuTokenRequest request,
  ) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$serviceUrl/sfu/get'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);
      return parseServer(response);
    } on CallException {
      rethrow;
    } on Exception catch (error) {
      throw CallTokenFailedException(cause: error);
    }
  }
}
