import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/domain/account/entities/account_boot_snapshot.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

/// Reads what the account state needs before the first frame. A value that
/// cannot be read falls back to "none": the app still starts.
class AccountBootSnapshotSource {
  AccountBootSnapshotSource(Store store)
    : _persistedActiveAccount = PersistedActiveAccountSource(store),
      _pendingRemovals = PendingRemovalsSource(store);

  final PersistedActiveAccountSource _persistedActiveAccount;
  final PendingRemovalsSource _pendingRemovals;

  Future<AccountBootSnapshot> read() async {
    String? persistedActiveUserId;
    var pendingRemovalIds = <String>{};
    try {
      persistedActiveUserId = await _persistedActiveAccount.read();
    } catch (e, s) {
      Logs().w('Unable to read the persisted active account', e, s);
    }
    try {
      // Accounts whose removal did not finish before the last exit.
      pendingRemovalIds = await _pendingRemovals.read();
    } catch (e, s) {
      Logs().w('Unable to read the pending account removals', e, s);
    }
    return AccountBootSnapshot(
      persistedActiveUserId: persistedActiveUserId,
      pendingRemovalIds: pendingRemovalIds,
    );
  }
}
