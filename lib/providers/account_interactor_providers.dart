import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/usecases/add_account_interactor.dart';
import 'package:twake_chat/domain/account/usecases/adopt_boot_accounts_interactor.dart';
import 'package:twake_chat/domain/account/usecases/create_account_candidate_interactor.dart';
import 'package:twake_chat/domain/account/usecases/initialize_accounts_interactor.dart';
import 'package:twake_chat/domain/account/usecases/list_pending_push_removals_interactor.dart';
import 'package:twake_chat/domain/account/usecases/record_pending_removal_interactor.dart';
import 'package:twake_chat/domain/account/usecases/remove_account_interactor.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_transitions_provider.dart';

part 'account_interactor_providers.g.dart';

@Riverpod(keepAlive: true)
AdoptBootAccountsInteractor adoptBootAccountsInteractor(
  Ref ref,
  List<Client> clients,
) => AdoptBootAccountsInteractor(
  repository: ref.watch(accountRepositoryProvider),
  bootPort: ref.watch(accountBootPortProvider(clients)),
);

@Riverpod(keepAlive: true)
InitializeAccountsInteractor initializeAccountsInteractor(Ref ref) =>
    InitializeAccountsInteractor(
      repository: ref.watch(accountRepositoryProvider),
      transitions: ref.watch(accountTransitionsProvider),
    );

@Riverpod(keepAlive: true)
AddAccountInteractor addAccountInteractor(Ref ref) => AddAccountInteractor(
  repository: ref.watch(accountRepositoryProvider),
  transitions: ref.watch(accountTransitionsProvider),
);

@Riverpod(keepAlive: true)
RemoveAccountInteractor removeAccountInteractor(Ref ref) =>
    RemoveAccountInteractor(
      repository: ref.watch(accountRepositoryProvider),
      transitions: ref.watch(accountTransitionsProvider),
    );

@Riverpod(keepAlive: true)
RecordPendingRemovalInteractor recordPendingRemovalInteractor(Ref ref) =>
    RecordPendingRemovalInteractor(
      repository: ref.watch(accountRepositoryProvider),
    );

@Riverpod(keepAlive: true)
ListPendingPushRemovalsInteractor listPendingPushRemovalsInteractor(Ref ref) =>
    ListPendingPushRemovalsInteractor(
      repository: ref.watch(accountRepositoryProvider),
    );

@Riverpod(keepAlive: true)
CreateAccountCandidateInteractor createAccountCandidateInteractor(Ref ref) =>
    CreateAccountCandidateInteractor(
      repository: ref.watch(accountRepositoryProvider),
    );
