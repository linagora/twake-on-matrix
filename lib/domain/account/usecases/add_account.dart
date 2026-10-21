import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';

/// Registers the account that just logged in. The next state is computed
/// before the write, so an account that cannot be added is never stored, and
/// again after it, from the state that is current by then.
class AddAccountUseCase {
  const AddAccountUseCase({
    required AccountRepository repository,
    required AccountTransitions transitions,
  }) : _repository = repository,
       _transitions = transitions;

  final AccountRepository _repository;
  final AccountTransitions _transitions;

  /// The state with [id] added, or null when [id] is already registered (a
  /// repeated `loggedIn` event).
  Future<AccountsState?> execute(
    AccountsState Function() currentState,
    String id,
  ) async {
    final before = currentState();
    final listed = before is Active || before is Switching;
    if (listed && before.accounts.any((a) => a.id == id)) return null;
    final account = _repository.accountOf(id);
    _transitions.add(before, account);
    await _repository.addAccount(account);
    return _transitions.add(currentState(), account);
  }
}
