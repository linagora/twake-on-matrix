// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/main.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

/// A logged-in client whose sync loop runs against [FakeMatrixApi]. The user
/// is the one [FakeMatrixApi] defines a sync filter for: with another user the
/// filter call fails and the loop never reaches `/sync`.
Future<Client> _syncingClient() async {
  sqfliteFfiInit();
  if (!vod.isInitialized()) {
    await vod.init(libraryPath: './vodozemac/debug/');
  }
  final client = Client(
    'app_starter_test',
    httpClient: FakeMatrixApi(),
    database: await MatrixSdkDatabase.init(
      'app_starter_test',
      database: await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      ),
      sqfliteFactory: databaseFactoryFfi,
    ),
  );
  await client.checkHomeserver(
    Uri.parse('https://fakeServer.notExisting'),
    checkWellKnown: false,
  );
  await client.init(
    newToken: 'abcd',
    newUserID: '@test:fakeServer.notExisting',
    newHomeserver: client.homeserver,
    newDeviceName: 'Test Client',
    newDeviceID: 'GHTYAJCE',
    waitForFirstSync: false,
  );
  return client;
}

int _syncCalls() => FakeMatrixApi.calledEndpoints.entries
    .where((e) => e.key.startsWith('/client/v3/sync'))
    .fold(0, (sum, e) => sum + e.value.length);

/// The `/sync` calls made during [window], once a running sync had time to end.
Future<int> _syncCallsDuring(Duration window) async {
  await Future.delayed(const Duration(milliseconds: 300));
  final before = _syncCalls();
  await Future.delayed(window);
  return _syncCalls() - before;
}

void main() {
  const window = Duration(milliseconds: 600);
  late Client client;
  late int guiStarts;
  late AppStarter starter;

  setUp(() async {
    client = await _syncingClient();
    guiStarts = 0;
    starter = AppStarter([client], () async => guiStarts++);
  });

  tearDown(() => client.dispose());

  test('the client keeps syncing until the sync is stopped', () async {
    expect(await _syncCallsDuring(window), isPositive);
  });

  test('a push-started app does not keep syncing in the background', () async {
    starter.stopBackgroundSync();

    expect(await _syncCallsDuring(window), 0);
    expect(guiStarts, 0);
  });

  test('a detached lifecycle change keeps the sync stopped', () async {
    starter.stopBackgroundSync();
    starter.didChangeAppLifecycleState(AppLifecycleState.detached);

    expect(await _syncCallsDuring(window), 0);
    expect(guiStarts, 0);
  });

  test('leaving detached starts the GUI once and syncs again', () async {
    starter.stopBackgroundSync();
    await _syncCallsDuring(window);

    starter.didChangeAppLifecycleState(AppLifecycleState.resumed);
    starter.didChangeAppLifecycleState(AppLifecycleState.inactive);

    expect(await _syncCallsDuring(window), isPositive);
    expect(guiStarts, 1);
  });
}
