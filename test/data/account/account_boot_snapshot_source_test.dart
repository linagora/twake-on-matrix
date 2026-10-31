import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/account/sources/account_boot_snapshot_source.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

class _UnreadableStore extends Store {
  _UnreadableStore(this.unreadableKey);

  final String unreadableKey;

  @override
  Future<String?> getItem(String key) => key == unreadableKey
      ? Future.error(StateError('unreadable'))
      : super.getItem(key);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reads the persisted active user and the pending removals', () async {
    await PersistedActiveAccountSource(Store()).write('@a:s');
    await PendingRemovalsSource(Store()).write({'b'});

    final snapshot = await AccountBootSnapshotSource(Store()).read();

    expect(snapshot.persistedActiveUserId, '@a:s');
    expect(snapshot.pendingRemovalIds, {'b'});
  });

  test(
    'with nothing stored there is no active user and nothing pending',
    () async {
      final snapshot = await AccountBootSnapshotSource(Store()).read();

      expect(snapshot.persistedActiveUserId, isNull);
      expect(snapshot.pendingRemovalIds, isEmpty);
    },
  );

  test('an unreadable active user falls back, the removals are kept', () async {
    await PendingRemovalsSource(Store()).write({'b'});

    final snapshot = await AccountBootSnapshotSource(
      _UnreadableStore(PersistedActiveAccountSource.key),
    ).read();

    expect(snapshot.persistedActiveUserId, isNull);
    expect(snapshot.pendingRemovalIds, {'b'});
  });

  test('unreadable removals fall back, the active user is kept', () async {
    await PersistedActiveAccountSource(Store()).write('@a:s');

    final snapshot = await AccountBootSnapshotSource(
      _UnreadableStore(PendingRemovalsSource.key),
    ).read();

    expect(snapshot.persistedActiveUserId, '@a:s');
    expect(snapshot.pendingRemovalIds, isEmpty);
  });
}
