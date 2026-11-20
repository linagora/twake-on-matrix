import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/utils/background_push.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../fake_client.dart';

const _notificationsChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

const _unreadRoomId = '!unread:example.com';
const _readRoomId = '!read:example.com';

class _SyncControlledApi extends FakeMatrixApi {
  bool failSync = false;
  bool holdSync = false;
  final List<Completer<void>> heldSyncs = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path.endsWith('/filter')) {
      return http.StreamedResponse(
        Stream.value(utf8.encode('{"filter_id":"1234"}')),
        200,
      );
    }
    if (request.url.path.endsWith('/sync')) {
      if (holdSync) {
        final release = Completer<void>();
        heldSyncs.add(release);
        await release.future;
      }
      if (failSync) throw http.ClientException('Connection refused');
    }
    return super.send(request);
  }
}

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.currentClients);

  @override
  final List<Client?> currentClients;

  @override
  String? get activeRoomId => null;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'MatrixState';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SyncControlledApi api;
  late Client client;
  late BackgroundPush push;
  late List<int> cancelledIds;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    cancelledIds = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'cancel') {
            cancelledIds.add((call.arguments as Map)['id'] as int);
          }
          return null;
        });
    // One instance for all tests: BackgroundPush keeps the first one.
    await (await SharedPreferences.getInstance()).setString(
      SettingKeys.notificationCurrentIds,
      json.encode({_unreadRoomId: 1, _readRoomId: 2}),
    );
    api = _SyncControlledApi();
    final database = await MatrixSdkDatabase.init(
      'background_push_clearing_push_test',
      database: await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      ),
      sqfliteFactory: databaseFactoryFfi,
    );
    client = await getClient(database: database, httpClient: api)
      ..backgroundSync = false;
    // The room was read on another device; the unread one was not.
    client.rooms.addAll([
      Room(id: _unreadRoomId, client: client, notificationCount: 1),
      Room(id: _readRoomId, client: client),
    ]);
    push = BackgroundPush.clientOnly(client)..rebind(client);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
  });

  Future<Map<String, dynamic>> storedIds() async => json.decode(
    (await SharedPreferences.getInstance()).getString(
          SettingKeys.notificationCurrentIds,
        ) ??
        '{}',
  );

  Future<void> waitUntil(bool Function() condition) async {
    for (var i = 0; i < 500 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> settle() => waitUntil(() => cancelledIds.isNotEmpty);

  void clearingPush() => push.onReceiveNotification({
    'data': {'unread': '1', 'prio': 'high'},
  });

  test(
    'a clearing push removes the notification of a room read elsewhere',
    () async {
      clearingPush();
      await settle();

      expect(cancelledIds, [2]);
      expect((await storedIds()).keys, [_unreadRoomId]);
    },
  );

  test('a failed sync keeps the notifications', () async {
    api.failSync = true;
    var syncErrors = 0;
    final statuses = client.onSyncStatus.stream.listen((update) {
      if (update.status == SyncStatus.error) syncErrors++;
    });
    addTearDown(statuses.cancel);

    clearingPush();
    await waitUntil(() => syncErrors > 0 && !client.syncPending);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(cancelledIds, isEmpty);
    expect((await storedIds()).keys, [_unreadRoomId, _readRoomId]);
  });

  test('a clearing push during a sweep gets its own sync', () async {
    final readRoom = client.getRoomById(_readRoomId)!..notificationCount = 1;
    api.holdSync = true;
    clearingPush();
    await waitUntil(() => api.heldSyncs.isNotEmpty);

    clearingPush();
    api.heldSyncs.first.complete();
    await waitUntil(() => api.heldSyncs.length == 2);
    readRoom.notificationCount = 0;
    api.holdSync = false;
    api.heldSyncs.last.complete();
    await settle();

    expect(cancelledIds, [2]);
  });

  // Last: the service keeps the host they set for the tests that follow.
  test(
    'the account served logged out: the sweep clears for the one still logged in',
    () async {
      final departed = Client(
        'departed',
        httpClient: api,
        database: await MatrixSdkDatabase.init(
          'departed',
          database: await databaseFactoryFfi.openDatabase(
            inMemoryDatabasePath,
            options: OpenDatabaseOptions(singleInstance: false),
          ),
          sqfliteFactory: databaseFactoryFfi,
        ),
      );
      push.rebind(departed);
      BackgroundPush(_FakeMatrixState([departed, client]), departed);

      clearingPush();
      await settle();

      expect(cancelledIds, [2]);
      expect((await storedIds()).keys, [_unreadRoomId]);
    },
  );

  test(
    'a clearing push for an account not signed in here does nothing',
    () async {
      BackgroundPush(_FakeMatrixState([client]), client);
      api.holdSync = true;

      push.onReceiveNotification({
        'receiver_id': '@stranger:example.com',
        'unread': '1',
        'prio': 'high',
      });
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(api.heldSyncs, isEmpty);
      expect(cancelledIds, isEmpty);
    },
  );
}
