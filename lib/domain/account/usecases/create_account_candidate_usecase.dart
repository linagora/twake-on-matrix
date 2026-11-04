import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';

/// A new unlogged account for "add another account"; it is not stored until
/// it logs in and is added.
class CreateAccountCandidateUseCase {
  const CreateAccountCandidateUseCase({required AccountRepository repository})
    : _repository = repository;

  final AccountRepository _repository;

  Future<Account> execute() => _repository.createCandidate();
}
