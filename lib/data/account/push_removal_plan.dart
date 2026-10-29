import 'package:twake_chat/domain/account/repositories/account_repository.dart';
import 'package:twake_chat/data/account/logout_removals.dart';

/// The steps that delete the push registration of an account before its
/// logout, kept by a [LogoutRemovals] so a failure is retried. While it
/// fails the account is recorded across restarts; once it works (or the
/// session it was made for is closed, when no deletion can ever work, even if
/// the account logs in again) the record is cleared.
class PushRemovalPlan {
  PushRemovalPlan({
    required this.id,
    required AccountRepository repository,
    required String? Function() sessionToken,
    required Future<void> Function() removePush,
    required bool Function() isPushReady,
  }) : _repository = repository,
       _sessionToken = sessionToken,
       _openedWith = sessionToken(),
       _removePush = removePush,
       _isPushReady = isPushReady;

  final String id;
  final AccountRepository _repository;
  final String? Function() _sessionToken;

  /// The token of the session this plan was made for (null: none was open).
  final String? _openedWith;
  final Future<void> Function() _removePush;

  /// False while the push set-up has not started (at boot, before the token
  /// is known): nothing can be deleted yet, which is a failure, not a success,
  /// so the record stays and the deletion runs again.
  final bool Function() _isPushReady;

  late final RemovalSteps steps = RemovalSteps(
    remove: _remove,
    hold: () async {},
    persist: () => _repository.markPushRemovalPending(id),
    settle: () => _repository.clearPushRemovalPending(id),
    settleOnHold: false,
  );

  /// The tries in this process that found the push not set up. Past
  /// [maxNotReadyTries] (a device that never gets a push token) the deletion
  /// is not retried in the background any more; its record stays, so a later
  /// start of the app deletes the pusher once the token is known.
  int _notReadyTries = 0;
  static const maxNotReadyTries = 3;

  Future<void> _remove() async {
    final token = _openedWith;
    if (token == null || _sessionToken() != token) return;
    if (!_isPushReady()) {
      _notReadyTries++;
      throw PushNotReadyException(
        retryInBackground: _notReadyTries < maxNotReadyTries,
      );
    }
    await _removePush();
  }
}

/// The push set-up of this device has not finished, so a pusher cannot be
/// deleted yet; the deletion is retried, quietly and a bounded number of
/// times.
class PushNotReadyException implements ExpectedRemovalFailure {
  const PushNotReadyException({this.retryInBackground = true});

  @override
  final bool retryInBackground;

  @override
  String toString() => 'PushNotReadyException: push is not set up yet';
}
