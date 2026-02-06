// ignore_for_file: depend_on_referenced_packages

import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

const ssssPassphrase = 'nae7ahDiequ7ohniufah3ieS2je1thohX4xeeka7aixohsho9O';
const ssssKey = 'EsT9 RzbW VhPW yqNp cC7j ViiW 5TZB LuY4 ryyv 9guN Ysmr WDPH';

class MockDatabase extends Mock implements DatabaseApi {
  @override
  Future<Map<String, dynamic>?> getClient(String name) {
    return Future.value(null);
  }

  @override
  Future insertClient(
    String name,
    String homeserverUrl,
    String token,
    DateTime? tokenExpiresAt,
    String? refreshToken,
    String userId,
    String? deviceId,
    String? deviceName,
    String? prevBatch,
    String? olmAccount,
  ) {
    return Future.value(null);
  }

  @override
  Future<Map<String, DeviceKeysList>> getUserDeviceKeys(Client client) {
    return Future.value({});
  }

  @override
  Future<List<Room>> getRoomList(Client client) {
    return Future.value([]);
  }

  @override
  Future<Map<String, BasicEvent>> getAccountData() {
    return Future.value({});
  }

  @override
  Future<User?> getUser(String userId, Room room) {
    return Future.value(null);
  }

  @override
  Future<({Map<String, Object?> content, DateTime savedAt})?>
  getCustomCacheObject(String key) {
    return Future.value(null);
  }

  @override
  Future<void> cacheCustomObject(
    String key,
    Map<String, Object?> content, {
    DateTime? savedAt,
  }) {
    return Future.value();
  }
}

Future<Client> getClient() async {
  if (!vod.isInitialized()) {
    await vod.init(
      libraryPath: './vodozemac/debug/',
    );
  }
  final client = Client(
    'testclient',
    httpClient: FakeMatrixApi(),
    database: MockDatabase(),
  );
  await client.checkHomeserver(
    Uri.parse('https://fakeServer.notExisting'),
    checkWellKnown: false,
  );
  await client.init(
    newToken: 'abcd',
    newUserID: '@admin:fakeServer',
    newHomeserver: client.homeserver,
    newDeviceName: 'Text Matrix Client',
    newDeviceID: 'GHTYAJCE',
  );
  await Future.delayed(const Duration(milliseconds: 10));
  return client;
}
