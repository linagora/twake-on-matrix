import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:twake_chat/data/datasource_impl/call/sfu_call_token_datasource_impl.dart';
import 'package:twake_chat/data/model/call/sfu_token_request.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

const _request = SfuTokenRequest(
  room: '!room:hs.test',
  openidToken: {'access_token': 'openid'},
  deviceId: 'BOB',
);

void main() {
  test('fetchServer_always_postsTheRequestToTheTokenService', () async {
    // Arrange
    final requests = <http.Request>[];
    final datasource = SfuCallTokenDatasourceImpl(
      MockClient((request) async {
        requests.add(request);
        return http.Response('{"url":"wss://lk.test","jwt":"jwt"}', 200);
      }),
    );

    // Act
    final server = await datasource.fetchServer('https://rtc.test', _request);

    // Assert
    expect(server, const CallServer(url: 'wss://lk.test', token: 'jwt'));
    expect(requests.single.url, Uri.parse('https://rtc.test/sfu/get'));
    expect(jsonDecode(requests.single.body), {
      'room': '!room:hs.test',
      'openid_token': {'access_token': 'openid'},
      'device_id': 'BOB',
    });
  });

  test('fetchServer_whenTheRequestFails_isATokenFailure', () async {
    // Arrange
    final datasource = SfuCallTokenDatasourceImpl(
      MockClient((_) async => throw http.ClientException('offline')),
    );

    // Act & Assert
    await expectLater(
      datasource.fetchServer('https://rtc.test', _request),
      throwsA(isA<CallTokenFailedException>()),
    );
  });

  test('parseServer_withAUrlAndAJwt_readsTheLiveKitServer', () {
    // Act
    final server = SfuCallTokenDatasourceImpl.parseServer(
      http.Response('{"url":"ws://127.0.0.1:7880","jwt":"token"}', 200),
    );

    // Assert
    expect(
      server,
      const CallServer(url: 'ws://127.0.0.1:7880', token: 'token'),
    );
  });

  test('parseServer_withAnErrorStatus_isATokenFailure', () {
    // Act & Assert
    expect(
      () => SfuCallTokenDatasourceImpl.parseServer(http.Response('{}', 403)),
      throwsA(isA<CallTokenFailedException>()),
    );
  });

  test('parseServer_withoutUrlOrJwt_isATokenFailure', () {
    // Act & Assert
    expect(
      () => SfuCallTokenDatasourceImpl.parseServer(
        http.Response('{"url":"ws://x"}', 200),
      ),
      throwsA(isA<CallTokenFailedException>()),
    );
  });
}
