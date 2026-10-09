import 'package:twake_chat/data/model/drive/drive_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource/drive/drive_bridge_datasource.dart';
import 'package:twake_chat/data/datasource/drive/drive_token_datasource.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_response.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_request.dart';
import 'package:twake_chat/data/model/drive/drive_token_exchange_response.dart';
import 'package:twake_chat/data/repository/drive/drive_session_repository_impl.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_config.dart';
import '../../datasource_impl/drive/drive_test_fixtures.dart';

final _validResponse = fakeSessionResponse();

class _FakeBridgeDatasource implements DriveBridgeDatasource {
  _FakeBridgeDatasource({DrivePickerSessionResponse? response, this.error})
    : response = response ?? _validResponse;

  final DrivePickerSessionResponse response;
  final Object? error;
  final List<DrivePickerSessionRequest> requests = [];

  @override
  bool get isAvailable => true;

  @override
  Future<DrivePickerSessionResponse> createPickerSession(
    DrivePickerSessionRequest request,
  ) async {
    requests.add(request);
    if (error != null) throw error!;
    return response;
  }
}

class _FakeTokenDatasource implements DriveTokenDatasource {
  final List<String> calls = [];
  String? lastAccessToken;
  Uri? lastPlatformUrl;

  @override
  Future<DriveTokenExchangeResponse> exchangeToken(
    Uri platformUrl,
    DriveTokenExchangeRequest request,
  ) async {
    calls.add('exchange:${request.idToken}');
    return const DriveTokenExchangeResponse(accessToken: 'drive-access');
  }

  @override
  Future<DrivePickerSessionResponse> createPickerSession({
    required Uri platformUrl,
    required String accessToken,
    required DrivePickerSessionRequest request,
  }) async {
    calls.add('intent');
    lastAccessToken = accessToken;
    lastPlatformUrl = platformUrl;
    return _validResponse;
  }
}

const _config = DrivePickerConfig(
  linkAction: DrivePickerAction(label: 'Add as link'),
  attachmentAction: DrivePickerAction(
    label: 'Add as attachment',
    maxFileSize: 1000,
    availableSize: 500,
  ),
  isDark: true,
);

DriveSessionRepositoryImpl _repository({
  _FakeBridgeDatasource? bridge,
  _FakeTokenDatasource? token,
}) => DriveSessionRepositoryImpl(
  bridge ?? _FakeBridgeDatasource(),
  token ?? _FakeTokenDatasource(),
);

Future<void> _mapsTheConfigToTheRequest() async {
  final bridge = _FakeBridgeDatasource();

  await _repository(bridge: bridge).createPickerSessionViaBridge(_config);

  final request = bridge.requests.single;
  expect(request.data.attributes.data.sharingLink.label, 'Add as link');
  expect(request.data.attributes.data.downloadLink?.maxFileSize, 1000);
  expect(request.data.attributes.data.downloadLink?.availableSize, 500);
  expect(request.data.attributes.data.theme.type, DriveThemeType.dark);
}

Future<void> _mapsTheResponseToTheIntent() async {
  final intent = await _repository().createPickerSessionViaBridge(_config);

  expect(intent.id, 'intent-1');
  expect(intent.url, Uri.parse('https://drive.example/intents/intent-1'));
  expect(intent.client, 'twake-chat');
}

Future<void> _rejectsUnsafeIntents() async {
  final unsafe = [
    fakeSessionResponse(href: 'http://drive.example/i'),
    fakeSessionResponse(id: '  '),
    fakeSessionResponse(href: '/relative/path'),
    fakeSessionResponse(href: 'https:relative'),
    fakeSessionResponse(href: 'https:///no-host'),
    fakeSessionResponse(href: null),
  ];

  for (final response in unsafe) {
    await expectLater(
      _repository(
        bridge: _FakeBridgeDatasource(response: response),
      ).createPickerSessionViaBridge(_config),
      throwsFormatException,
    );
  }
}

Future<void> _neverFallsBackToTokenWhenTheBridgeFails() async {
  final token = _FakeTokenDatasource();
  final bridge = _FakeBridgeDatasource(error: StateError('bridge down'));

  await expectLater(
    _repository(
      bridge: bridge,
      token: token,
    ).createPickerSessionViaBridge(_config),
    throwsStateError,
  );
  expect(token.calls, isEmpty);
}

Future<void> _exchangesTheIdTokenForAnAccessToken() async {
  final token = _FakeTokenDatasource();

  final accessToken = await _repository(
    token: token,
  ).exchangeToken(Uri.parse('https://workplace.example'), 'id-token');

  expect(accessToken, 'drive-access');
  expect(token.calls, ['exchange:id-token']);
}

Future<void> _createsTheIntentWithTheAccessToken() async {
  final token = _FakeTokenDatasource();
  final platformUrl = Uri.parse('https://workplace.example');

  final intent = await _repository(token: token).createPickerSessionWithToken(
    platformUrl: platformUrl,
    accessToken: 'drive-access',
    config: _config,
  );

  expect(intent.id, 'intent-1');
  expect(token.lastAccessToken, 'drive-access');
  expect(token.lastPlatformUrl, platformUrl);
}

void main() {
  test('maps the config to the request', _mapsTheConfigToTheRequest);
  test('maps the response to the intent', _mapsTheResponseToTheIntent);
  test('rejects unsafe intents', _rejectsUnsafeIntents);
  test(
    'never falls back to the token when the bridge fails',
    _neverFallsBackToTokenWhenTheBridgeFails,
  );
  test(
    'exchanges the id token for an access token',
    _exchangesTheIdTokenForAnAccessToken,
  );
  test(
    'creates the intent with the access token',
    _createsTheIntentWithTheAccessToken,
  );
}
