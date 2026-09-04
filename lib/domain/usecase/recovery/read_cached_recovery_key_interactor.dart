import 'package:twake_chat/domain/app_state/recovery/cached_recovery_key_state.dart';
import 'package:twake_chat/domain/repository/recovery_key_storage_repository.dart';
import 'package:twake_chat/utils/logging/sentry_tracked_events.dart';
import 'package:matrix/matrix.dart';

/// Reads the recovery key previously cached for a user (via
/// [StoreRecoveryKeyInteractor]) so bootstrap can prefill/auto-retry
/// without asking the user to re-enter it.
class ReadCachedRecoveryKeyInteractor {
  const ReadCachedRecoveryKeyInteractor(this._repository);

  final RecoveryKeyStorageRepository _repository;

  Future<CachedRecoveryKeyState> execute({required String userId}) async {
    try {
      final key = await _repository.read(userId: userId);
      return key == null
          ? const CachedRecoveryKeyState.notFound()
          : CachedRecoveryKeyState.found(recoveryKey: key);
    } catch (e, s) {
      Logs().w(SentryTrackedEvents.unableToReadCachedRecoveryKey.message, e, s);
      return CachedRecoveryKeyState.failure(exception: e);
    }
  }
}
