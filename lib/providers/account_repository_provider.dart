import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';
import 'package:twake_chat/data/account/datasources_impl/client_manager_account_data_source.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

part 'account_repository_provider.g.dart';

/// The `Client` of every known account; the only id to `Client` mapping.
@Riverpod(keepAlive: true)
AccountClientRegistry accountClientRegistry(Ref ref) => AccountClientRegistry();

@Riverpod(keepAlive: true)
AccountClientDataSource accountClientDataSource(Ref ref) =>
    ClientManagerAccountDataSource();

/// The concrete type is exposed because `adopt` hands the clients created at
/// boot to the repository; everything else goes through `AccountRepository`.
@Riverpod(keepAlive: true)
AccountRepositoryImpl accountRepository(Ref ref) => AccountRepositoryImpl(
  dataSource: ref.watch(accountClientDataSourceProvider),
  persistedActiveAccount: PersistedActiveAccountSource(Store()),
  pendingRemovals: PendingRemovalsSource(Store()),
  pendingPushRemovals: PendingRemovalsSource(
    Store(),
    storeKey: PendingRemovalsSource.pushKey,
  ),
  pendingCandidateDiscards: PendingRemovalsSource(
    Store(),
    storeKey: PendingRemovalsSource.candidateKey,
  ),
  registry: ref.watch(accountClientRegistryProvider),
);

/// The ids of the accounts whose removal was pending when the app started,
/// read before the first frame like [bootPersistedActiveUserId]. `main`
/// overrides it; without an override none is pending.
@Riverpod(keepAlive: true)
Set<String> bootPendingRemovalIds(Ref ref) => const {};

/// The user id persisted as the active account when the app started, read
/// before the first frame because the state is built synchronously. `main`
/// overrides it; without an override the first logged-in account is active.
@Riverpod(keepAlive: true)
String? bootPersistedActiveUserId(Ref ref) => null;
