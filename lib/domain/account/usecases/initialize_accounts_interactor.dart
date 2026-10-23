import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';

/// The account state at start, from the accounts the repository registered.
class InitializeAccountsInteractor {
  const InitializeAccountsInteractor({
    required AccountRepository repository,
    required AccountTransitions transitions,
  }) : _repository = repository,
       _transitions = transitions;

  final AccountRepository _repository;
  final AccountTransitions _transitions;

  AccountsState execute({String? persistedUserId}) => _transitions.initialize(
    const Booting(),
    _repository.registeredAccounts(),
    persistedUserId: persistedUserId,
  );
}
