import 'package:twake_chat/domain/account/repositories/account_repository.dart';

/// Drops the records of the pusher deletions whose account is gone: they
/// cannot be retried (this deletes records). One failing drop does not stop
/// the others; its error is thrown once they all ran, and its record is
/// dropped again at the next start. The retryable ones are read by
/// `RetryablePushRemovalsUseCase`, awaited on its own.
class PrunePendingPushRemovalsUseCase {
  const PrunePendingPushRemovalsUseCase({required AccountRepository repository})
    : _repository = repository;

  final AccountRepository _repository;

  Future<void> execute() async {
    final registered = {
      for (final account in _repository.registeredAccounts()) account.id,
    };
    final pending = await _repository.pendingPushRemovals();
    // `Future.wait` lets every drop run and only then throws the first error.
    await Future.wait([
      for (final id in pending)
        if (!registered.contains(id)) _repository.clearPushRemovalPending(id),
    ]);
  }
}
