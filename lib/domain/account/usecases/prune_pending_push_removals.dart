import 'package:twake_chat/domain/account/repositories/account_repository.dart';

/// The accounts whose pusher deletion failed before the last exit and can run
/// again. A record whose account is gone cannot be retried: it is dropped
/// here (this deletes records), and the accounts that remain are returned.
class PrunePendingPushRemovalsUseCase {
  const PrunePendingPushRemovalsUseCase({required AccountRepository repository})
    : _repository = repository;

  final AccountRepository _repository;

  Future<List<String>> execute() async {
    final registered = {
      for (final account in _repository.registeredAccounts()) account.id,
    };
    final retryable = <String>[];
    for (final id in await _repository.pendingPushRemovals()) {
      if (registered.contains(id)) {
        retryable.add(id);
      } else {
        await _repository.clearPushRemovalPending(id);
      }
    }
    return retryable;
  }
}
