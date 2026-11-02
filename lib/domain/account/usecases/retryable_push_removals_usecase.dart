import 'package:twake_chat/domain/account/repositories/account_repository.dart';

/// The accounts whose pusher deletion failed before the last exit and can run
/// again: the pending ones that are still registered. Deletes nothing.
class RetryablePushRemovalsUseCase {
  const RetryablePushRemovalsUseCase({required AccountRepository repository})
    : _repository = repository;

  final AccountRepository _repository;

  Future<List<String>> execute() async {
    final registered = {
      for (final account in _repository.registeredAccounts()) account.id,
    };
    final pending = await _repository.pendingPushRemovals();
    return [
      for (final id in pending)
        if (registered.contains(id)) id,
    ];
  }
}
