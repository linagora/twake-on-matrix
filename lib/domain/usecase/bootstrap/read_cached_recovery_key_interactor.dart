import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/bootstrap/cached_recovery_key_state.dart';
import 'package:fluffychat/utils/logging/sentry_tracked_events.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';

/// Reads the recovery key previously cached for [userId] (via
/// [StoreRecoveryKeyInteractor]) from secure storage, so bootstrap can
/// prefill/auto-retry without asking the user to re-enter it.
class ReadCachedRecoveryKeyInteractor {
  static String _secureStorageKey(String userId) => 'ssss_recovery_key_$userId';

  Stream<Either<Failure, Success>> execute({required String userId}) async* {
    try {
      final key = await const FlutterSecureStorage().read(
        key: _secureStorageKey(userId),
      );
      yield Right(
        key == null
            ? const CachedRecoveryKeyNotFoundState()
            : CachedRecoveryKeyFoundState(recoveryKey: key),
      );
    } catch (e, s) {
      // Sent to Sentry: this message matches
      // SentryTrackedEvents.unableToReadCachedRecoveryKey.
      Logs().w(SentryTrackedEvents.unableToReadCachedRecoveryKey.message, e, s);
      yield Left(ReadCachedRecoveryKeyFailureState(exception: e));
    }
  }
}
