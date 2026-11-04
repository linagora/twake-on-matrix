import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.provider.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.provider.dart';
import 'package:twake_chat/domain/account/usecases/initialize_accounts_usecase.dart';

part 'initialize_accounts_usecase.provider.g.dart';

// Kept alive: read by the session-wide accountsProvider, and a kept-alive
// provider cannot depend on an auto-dispose one.
@Riverpod(keepAlive: true)
InitializeAccountsUseCase initializeAccountsUseCase(Ref ref) =>
    InitializeAccountsUseCase(
      repository: ref.watch(accountRepositoryProvider),
      transitions: ref.watch(accountTransitionsProvider),
    );
