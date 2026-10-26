import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/usecases/add_account_usecase.dart';
import 'package:twake_chat/domain/account/usecases/adopt_boot_accounts_usecase.dart';
import 'package:twake_chat/domain/account/usecases/initialize_accounts_usecase.dart';
import 'package:twake_chat/domain/account/usecases/prune_pending_push_removals.dart';
import 'package:twake_chat/domain/account/usecases/remove_account_usecase.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_transitions_provider.dart';

part 'account_usecase_providers.g.dart';

@Riverpod(keepAlive: true)
AdoptBootAccountsUseCase adoptBootAccountsUseCase(Ref ref) =>
    AdoptBootAccountsUseCase(
      repository: ref.watch(accountRepositoryProvider),
      bootPort: ref.watch(accountBootPortProvider),
    );

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
PrunePendingPushRemovalsUseCase prunePendingPushRemovalsUseCase(
  Ref ref,
) => PrunePendingPushRemovalsUseCase(
  repository: ref.watch(accountRepositoryProvider),
);
