import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/client_manager.dart';

import '../fake_client.dart';

/// Review of #3621 (jbrnzl) and #3609 [7] (nqhhdev): the SDK defines a sync
/// filter only when none is saved, so the saved filter id must be dropped
/// whenever the threads flag differs from the state the saved filter was
/// defined for: also when the flag goes back to off.
///
/// Seam asked from the worker: `ClientManager.migrateSyncFilter(database,
/// clientName)`, the entry point `createClient` calls before building the
/// client (today: the private `_invalidatePersistedSyncFilterOnce`, called
/// twice). A saved filter id is dropped by re-inserting the account without
/// it, as today. The `ignore: undefined_method` below goes once it exists.
class _AccountDatabase extends MockDatabase {
  _AccountDatabase() {
    _storeFilterId();
  }

  /// How many times the account was re-inserted without its filter id.
  int invalidations = 0;
  Map<String, dynamic>? account;

  void _storeFilterId() => account = {
    'homeserver_url': 'https://example.org',
    'token': 'token',
    'user_id': '@me:example.org',
    'sync_filter_id': 'filter-1',
  };

  /// The SDK defines a new filter on the next sync.
  void syncDefinesAFilter() => _storeFilterId();

  @override
  Future<Map<String, dynamic>?> getClient(String name) async => account;

  @override
  Future<int> insertClient(
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
    String? oidcClientId,
  ) async {
    invalidations++;
    account = {...account!}..remove('sync_filter_id');
    return 0;
  }
}

void main() {
  const name = 'acct';
  late bool flagBefore;
  late _AccountDatabase database;

  setUp(() {
    flagBefore = AppConfig.threadsEnabled;
    // The leave-rooms migration is done: only the threads one is observed.
    SharedPreferences.setMockInitialValues({
      'im.twake.store.sync_filter_include_leave_v1.$name': '1',
    });
    database = _AccountDatabase();
  });
  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  Future<void> start({required bool threads}) async {
    AppConfig.threadsEnabled = threads;
    await ClientManager.migrateSyncFilter(database, name);
  }

  test('flag on for the first time: the saved filter id is dropped', () async {
    await start(threads: true);

    expect(database.account!['sync_filter_id'], isNull);
  });

  test('flag on at the next start: the filter is not dropped again', () async {
    await start(threads: true);
    database.syncDefinesAFilter();

    await start(threads: true);

    expect(database.account!['sync_filter_id'], 'filter-1');
  });

  test('flag turned back off: the filter that asks for thread counters is '
      'dropped, so the room counters come back', () async {
    await start(threads: true);
    database.syncDefinesAFilter();

    await start(threads: false);

    expect(database.account!['sync_filter_id'], isNull);
  });

  test('flag off at the next start after going back off: not dropped '
      'again', () async {
    await start(threads: true);
    await start(threads: false);
    database.syncDefinesAFilter();

    await start(threads: false);

    expect(database.account!['sync_filter_id'], 'filter-1');
  });

  test('flag turned on again after being off: dropped again', () async {
    await start(threads: true);
    await start(threads: false);
    database.syncDefinesAFilter();

    await start(threads: true);

    expect(database.account!['sync_filter_id'], isNull);
  });
}
