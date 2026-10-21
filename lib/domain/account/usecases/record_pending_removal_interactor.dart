import 'package:twake_chat/domain/account/repositories/account_repository.dart';

/// Records, across restarts, that the removal of an account is pending.
class RecordPendingRemovalInteractor {
  const RecordPendingRemovalInteractor({required AccountRepository repository})
    : _repository = repository;

  final AccountRepository _repository;

  Future<void> execute(String id) => _repository.markRemovalPending(id);
}
