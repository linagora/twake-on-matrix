import 'dart:io';

import 'package:twake_chat/data/datasource/drive/drive_token_datasource.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_response.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_request.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_response.dart';
import 'package:twake_chat/data/network/drive/drive_api.dart';
import 'package:twake_chat/data/network/drive/drive_json.dart';
import 'package:twake_chat/data/network/drive_endpoint.dart';
import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';

class DriveTokenDatasourceImpl implements DriveTokenDatasource {
  const DriveTokenDatasourceImpl(this._api);

  final DriveApi _api;

  @override
  Future<DriveTokenExchangeResponse> exchangeToken(
    Uri platformUrl,
    DriveTokenExchangeRequest request,
  ) async {
    final json = await _api.post(
      DriveEndpoint.tokenExchangeServicePath.resolveOn(platformUrl),
      body: request.toJson(),
      headers: {HttpHeaders.acceptHeader: 'application/json'},
    );
    final response = parseDriveJson(json, DriveTokenExchangeResponse.fromJson);
    if (response.accessToken.trim().isEmpty) {
      throw const FormatException('Drive token exchange has no access_token');
    }
    return response;
  }

  @override
  Future<DrivePickerSessionResponse> createPickerSession({
    required Uri platformUrl,
    required String accessToken,
    required DrivePickerSessionRequest request,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw const DriveAccessTokenMissingException();
    }
    final json = await _api.post(
      DriveEndpoint.pickerSessionServicePath.resolveOn(
        platformUrl,
        queryParameters: {DriveEndpoint.forceSessionIdQueryKey: 'true'},
      ),
      body: request.toJson(),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $accessToken'},
    );
    return parseDriveJson(json, DrivePickerSessionResponse.fromJson);
  }
}
