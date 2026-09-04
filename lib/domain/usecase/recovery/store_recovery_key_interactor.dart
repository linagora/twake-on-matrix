import 'package:twake_chat/domain/app_state/recovery/store_recovery_key_state.dart';
import 'package:twake_chat/domain/repository/recovery_key_storage_repository.dart';
import 'package:twake_chat/utils/logging/sentry_tracked_events.dart';
import 'package:matrix/matrix.dart';

/// Caches the recovery key in secure storage for a user, so a later
/// bootstrap run (e.g. "Retry automatically") can prefill/auto-unlock
/// without asking the user to re-enter it.
class StoreRecoveryKeyInteractor {
  const StoreRecoveryKeyInteractor(this._repository);

  final RecoveryKeyStorageRepository _repository;

  Future<StoreRecoveryKeyState> execute({
    required String userId,
    required String recoveryKey,
  }) async {
    try {
      await _repository.write(userId: userId, recoveryKey: recoveryKey);
      return const StoreRecoveryKeyState.success();
    } catch (e, s) {
      Logs().w(SentryTrackedEvents.unableToStoreRecoveryKey.message, e, s);
      return StoreRecoveryKeyState.failure(exception: e);
    }
  }
}
