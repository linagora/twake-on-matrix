import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';
import 'package:twake_chat/data/account/datasources_impl/client_manager_account_data_source.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';
import 'package:twake_chat/providers/store_provider.dart';

part 'account_repository_provider.g.dart';

/// The `Client` of every known account; the only id to `Client` mapping.
@Riverpod(keepAlive: true)
AccountClientRegistry accountClientRegistry(Ref ref) => AccountClientRegistry();

@Riverpod(keepAlive: true)
AccountClientDataSource accountClientDataSource(Ref ref) =>
    ClientManagerAccountDataSource();

/// The implementation, read by [accountRepository] and by the boot, which
/// hands it the clients created at boot (`adopt`).
@Riverpod(keepAlive: true)
AccountRepositoryImpl accountRepositoryImpl(Ref ref) {
  final store = ref.watch(storeProvider);
  return AccountRepositoryImpl(
    dataSource: ref.watch(accountClientDataSourceProvider),
    persistedActiveAccount: PersistedActiveAccountSource(store),
    pendingRemovals: PendingRemovalsSource(store),
    pendingPushRemovals: PendingRemovalsSource(
      store,
      storeKey: PendingRemovalsSource.pushKey,
    ),
    pendingCandidateDiscards: PendingRemovalsSource(
      store,
      storeKey: PendingRemovalsSource.candidateKey,
    ),
    registry: ref.watch(accountClientRegistryProvider),
  );
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) =>
    ref.watch(accountRepositoryImplProvider);
