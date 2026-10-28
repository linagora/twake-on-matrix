import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/usecases/add_account_usecase.dart';
import 'package:twake_chat/domain/account/usecases/create_account_candidate_usecase.dart';
import 'package:twake_chat/domain/account/usecases/initialize_accounts_usecase.dart';
import 'package:twake_chat/domain/account/usecases/prune_pending_push_removals_usecase.dart';
import 'package:twake_chat/domain/account/usecases/remove_account_usecase.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_transitions_provider.dart';

part 'account_usecase_providers.g.dart';

@Riverpod(keepAlive: true)
InitializeAccountsUseCase initializeAccountsUseCase(Ref ref) =>
    InitializeAccountsUseCase(
      repository: ref.watch(accountRepositoryProvider),
      transitions: ref.watch(accountTransitionsProvider),
    );

@Riverpod(keepAlive: true)
AddAccountUseCase addAccountUseCase(Ref ref) => AddAccountUseCase(
  repository: ref.watch(accountRepositoryProvider),
  transitions: ref.watch(accountTransitionsProvider),
);

@Riverpod(keepAlive: true)
RemoveAccountUseCase removeAccountUseCase(Ref ref) => RemoveAccountUseCase(
  repository: ref.watch(accountRepositoryProvider),
  transitions: ref.watch(accountTransitionsProvider),
);

@Riverpod(keepAlive: true)
PrunePendingPushRemovalsUseCase prunePendingPushRemovalsUseCase(Ref ref) =>
    PrunePendingPushRemovalsUseCase(
      repository: ref.watch(accountRepositoryProvider),
    );

@Riverpod(keepAlive: true)
CreateAccountCandidateUseCase createAccountCandidateUseCase(Ref ref) =>
    CreateAccountCandidateUseCase(
      repository: ref.watch(accountRepositoryProvider),
    );
