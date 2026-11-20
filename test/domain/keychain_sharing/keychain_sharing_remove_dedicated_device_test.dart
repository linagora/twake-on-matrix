import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_session.dart';
import 'package:twake_chat/utils/platform_infos.dart';

const _alice = '@alice:example.com';
const _bob = '@bob:example.com';
const _appDeviceId = 'APPDEVICE';

final _aliceNse = KeychainSharingSession(
  accessToken: 'alice-nse-token',
  userId: _alice,
  deviceId: 'NSEDEVICE',
  homeserverUrl: 'https://example.com',
);

final _aliceApp = KeychainSharingSession(
  accessToken: 'alice-app-token',
  userId: _alice,
  deviceId: _appDeviceId,
  homeserverUrl: 'https://example.com',
);

final _bobNse = KeychainSharingSession(
  accessToken: 'bob-nse-token',
  userId: _bob,
  deviceId: 'BOBNSE',
  homeserverUrl: 'https://example.com',
);

String _entry(KeychainSharingSession session, {bool? dedicated = true}) =>
    jsonEncode(
      KeychainSharingRestoreToken(
        session: session,
        dedicated: dedicated,
      ).toJson(),
    );

http.Response _ok() => http.Response('{}', 200);

http.Response _error(String errcode, int status) =>
    http.Response(jsonEncode({'errcode': errcode, 'error': errcode}), status);

/// The app's client for Alice.
class _FakeClient extends Fake implements Client {
  _FakeClient(this.httpClient);

  @override
  final http.Client httpClient;

  @override
  String? get userID => _alice;

  @override
  String? get deviceID => _appDeviceId;
}

void main() {
  late Map<String, String> store;
  late List<http.Request> requests;
  late Future<http.Response> Function() server;
  late Client client;

  setUp(() {
    store = {};
    requests = [];
    server = () async => _ok();
    FlutterSecureStorage.setMockInitialValues(store);
    PlatformInfos.isTestingForIOS = true;
    client = _FakeClient(
      MockClient((request) {
        requests.add(request);
        return server();
      }),
    );
  });

  tearDown(() => PlatformInfos.isTestingForIOS = false);

  Future<void> remove() =>
      KeychainSharingManager.removeDedicatedNotificationDevice(client);

  Iterable<http.Request> logouts() =>
      requests.where((r) => r.url.path.endsWith('/logout'));

  test('a dedicated device is logged out once, with its own token', () async {
    store[_alice] = _entry(_aliceNse);

    await remove();

    expect(requests, hasLength(1));
    expect(logouts(), hasLength(1));
    expect(logouts().single.method, 'POST');
    expect(
      logouts().single.headers['authorization'],
      'Bearer ${_aliceNse.accessToken}',
    );
  });

  test('once logged out, its keychain entry is gone', () async {
    store[_alice] = _entry(_aliceNse);

    await remove();

    expect(store.containsKey(_alice), isFalse);
    expect(await KeychainSharingManager.read(userId: _alice), isNull);
  });

  test('a device the server already revoked only loses its entry', () async {
    store[_alice] = _entry(_aliceNse);
    server = () async => _error('M_UNKNOWN_TOKEN', 401);

    await remove();

    expect(logouts(), hasLength(1));
    expect(store.containsKey(_alice), isFalse);
  });

  final failures = <({String name, Future<http.Response> Function() reply})>[
    (
      name: 'offline',
      reply: () async => throw http.ClientException('Connection refused'),
    ),
    (name: 'server error', reply: () async => _error('M_UNKNOWN', 500)),
    (
      name: 'server error without a body',
      reply: () async => http.Response('Internal Server Error', 500),
    ),
  ];

  for (final failure in failures) {
    test('${failure.name}: the entry stays for the next launch', () async {
      store[_alice] = _entry(_aliceNse);
      server = failure.reply;

      await remove();

      expect(logouts(), hasLength(1));
      expect(store[_alice], _entry(_aliceNse));
    });

    test('${failure.name}: the next call logs out and removes it', () async {
      store[_alice] = _entry(_aliceNse);
      server = failure.reply;
      await remove();
      server = () async => _ok();

      await remove();

      expect(logouts(), hasLength(2));
      expect(
        logouts().last.headers['authorization'],
        'Bearer ${_aliceNse.accessToken}',
      );
      expect(store.containsKey(_alice), isFalse);
    });
  }

  final nothingToLogOut = <({String name, String? entry})>[
    (name: 'no entry', entry: null),
    (
      name: 'an entry not marked dedicated',
      entry: _entry(_aliceNse, dedicated: null),
    ),
    (
      name: 'an entry marked not dedicated',
      entry: _entry(_aliceNse, dedicated: false),
    ),
    (name: "the app's own session", entry: _entry(_aliceApp)),
  ];

  for (final c in nothingToLogOut) {
    test('${c.name}: no network call', () async {
      if (c.entry != null) store[_alice] = c.entry!;

      await remove();

      expect(requests, isEmpty);
    });
  }

  test('the entry of another account is left alone', () async {
    store[_alice] = _entry(_aliceNse);
    store[_bob] = _entry(_bobNse);

    await remove();

    expect(store[_bob], _entry(_bobNse));
    expect(
      requests.map((r) => r.headers['authorization']),
      isNot(contains('Bearer ${_bobNse.accessToken}')),
    );
  });

  test('the http_ entry of the extension is left alone', () async {
    const httpEntry = '{"accessToken":"alice-app-token"}';
    store[_alice] = _entry(_aliceNse);
    store['http_$_alice'] = httpEntry;

    await remove();

    expect(store['http_$_alice'], httpEntry);
  });

  test('outside iOS, nothing is called and the entry stays', () async {
    PlatformInfos.isTestingForIOS = false;
    store[_alice] = _entry(_aliceNse);

    await remove();

    expect(requests, isEmpty);
    expect(store[_alice], _entry(_aliceNse));
  });
}
