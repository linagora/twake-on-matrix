import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource_impl/drive/drive_token_datasource_impl.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/drive/drive_api.dart';
import 'package:twake_chat/data/model/drive/drive_picker_action_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_request.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_request.dart';
import 'package:twake_chat/data/network/drive/drive_dio.dart';
import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';

import 'drive_test_fixtures.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

final _platformUrl = Uri.parse('https://workplace.example');

DriveTokenDatasourceImpl _datasource(_RecordingAdapter adapter) =>
    DriveTokenDatasourceImpl(
      DriveApi(DioClient(createDriveDio()..httpClientAdapter = adapter)),
    );

_RecordingAdapter _adapterReturning(Object body, {int status = 200}) =>
    _RecordingAdapter((_) => _json(body, status: status));

Future<void> _exchangePostsTheIdTokenAndReturnsTheAccessToken() async {
  final adapter = _adapterReturning({'access_token': 'drive-access'});

  final response = await _datasource(adapter).exchangeToken(
    _platformUrl,
    DriveTokenExchangeRequest.app(idToken: 'id-token'),
  );

  expect(response.accessToken, 'drive-access');
  final request = adapter.requests.single;
  expect(
    request.uri.toString(),
    'https://workplace.example/auth/token_exchange',
  );
  expect(request.data, {'id_token': 'id-token', 'exchange_type': 'app'});
}

Future<void> _exchangeFailsWhenTheResponseIsBad() async {
  final badResponses = [
    _adapterReturning({'scope': 'x'}),
    _adapterReturning({'access_token': '  '}),
  ];

  for (final adapter in badResponses) {
    await expectLater(
      _datasource(adapter).exchangeToken(
        _platformUrl,
        DriveTokenExchangeRequest.app(idToken: 'id-token'),
      ),
      throwsFormatException,
    );
  }
}

Future<void> _exchangeMapsAnInvalidTokenToAnAuthError() async {
  final adapter = _adapterReturning({'error': 'invalid token'}, status: 400);

  await expectLater(
    _datasource(adapter).exchangeToken(
      _platformUrl,
      DriveTokenExchangeRequest.app(idToken: 'bad'),
    ),
    throwsA(isA<DriveAuthRejectedException>()),
  );
}

Future<void> _intentSendsBearerSessionFlagAndPickerConfig() async {
  final adapter = _adapterReturning(drivePickerSessionResponseJson());

  final response = await _datasource(adapter).createPickerSession(
    platformUrl: _platformUrl,
    accessToken: 'drive-access',
    request: drivePickerSessionRequest,
  );

  final request = adapter.requests.single;
  expect(request.headers['Authorization'], 'Bearer drive-access');
  expect(request.uri.path, '/intents');
  expect(request.uri.queryParameters['force_session_id'], 'true');
  final pickerData = (request.data as Map)['data']['attributes']['data'] as Map;
  expect(pickerData['downloadLink'], {
    'label': 'Add as attachment',
    'maxFileSize': 1000,
    'availableSize': 1000,
  });
  expect(response.id, 'intent-1');
  expect(response.href, 'https://drive.example/intents/intent-1');
}

Future<void> _intentHidesDownloadLinkWithoutAttachments() async {
  final adapter = _adapterReturning(drivePickerSessionResponseJson());

  await _datasource(adapter).createPickerSession(
    platformUrl: _platformUrl,
    accessToken: 'drive-access',
    request: DrivePickerSessionRequest.pick(
      sharingLink: const DrivePickerActionRequest(label: 'Add as link'),
    ),
  );

  final data = adapter.requests.single.data as Map;
  final pickerData = data['data']['attributes']['data'] as Map;
  expect(pickerData.containsKey('downloadLink'), isTrue);
  expect(pickerData['downloadLink'], isNull);
}

Future<void> _intentFailsWhenTheResponseIsMalformed() async {
  final adapter = _adapterReturning({'unexpected': true});

  await expectLater(
    _datasource(adapter).createPickerSession(
      platformUrl: _platformUrl,
      accessToken: 'drive-access',
      request: drivePickerSessionRequest,
    ),
    throwsFormatException,
  );
}

Future<void> _intentFailsBeforeAnyRequestWithABlankToken() async {
  final adapter = _adapterReturning(drivePickerSessionResponseJson());

  await expectLater(
    _datasource(adapter).createPickerSession(
      platformUrl: _platformUrl,
      accessToken: '  ',
      request: drivePickerSessionRequest,
    ),
    throwsA(isA<DriveAccessTokenMissingException>()),
  );
  expect(adapter.requests, isEmpty);
}

void main() {
  test(
    'exchange posts the id token and returns the access token',
    _exchangePostsTheIdTokenAndReturnsTheAccessToken,
  );
  test(
    'exchange fails when the response is bad',
    _exchangeFailsWhenTheResponseIsBad,
  );
  test(
    'exchange maps an invalid token to an auth error',
    _exchangeMapsAnInvalidTokenToAnAuthError,
  );
  test(
    'intent sends bearer, session flag and picker config',
    _intentSendsBearerSessionFlagAndPickerConfig,
  );
  test(
    'intent hides downloadLink without attachments',
    _intentHidesDownloadLinkWithoutAttachments,
  );
  test(
    'intent fails when the response is malformed',
    _intentFailsWhenTheResponseIsMalformed,
  );
  test(
    'intent fails before any request with a blank token',
    _intentFailsBeforeAnyRequestWithABlankToken,
  );
}
