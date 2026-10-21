import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';

/// Removes an account. When it was the active one the next one becomes active
/// in the same state.
class RemoveAccountUseCase {
  const RemoveAccountUseCase({
    required AccountRepository repository,
    required AccountTransitions transitions,
  }) : _repository = repository,
       _transitions = transitions;

  final AccountRepository _repository;
  final AccountTransitions _transitions;

  /// The state without [id]; the removal is checked against the state before
  /// anything is deleted, and applied to the one that is current afterwards.
  Future<AccountsState> execute(
    AccountsState Function() currentState,
    String id,
  ) async {
    _transitions.remove(currentState(), id);
    await _repository.removeAccount(id);
    return _transitions.remove(currentState(), id);
  }
}
