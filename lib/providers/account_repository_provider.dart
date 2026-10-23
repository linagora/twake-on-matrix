import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';
import 'package:twake_chat/data/account/datasources_impl/client_manager_account_data_source.dart';
import 'package:twake_chat/data/account/datasources_impl/fault_injecting_account_data_source.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.dart';
import 'package:twake_chat/data/account/repositories/client_account_boot_port.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/domain/account/repositories/account_boot_port.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

part 'account_repository_provider.g.dart';

/// The `Client` of every known account; the only id to `Client` mapping.
@Riverpod(keepAlive: true)
AccountClientRegistry accountClientRegistry(Ref ref) => AccountClientRegistry();

@Riverpod(keepAlive: true)
AccountClientDataSource accountClientDataSource(Ref ref) => kDebugMode
    ? FaultInjectingAccountDataSource(ClientManagerAccountDataSource())
    : ClientManagerAccountDataSource();

/// The implementation, read only by [accountRepository] and [accountBootPort].
@Riverpod(keepAlive: true)
AccountRepositoryImpl accountRepositoryImpl(Ref ref) => AccountRepositoryImpl(
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

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) =>
    ref.watch(accountRepositoryImplProvider);

/// Hands the clients created at boot to the repository.
@Riverpod(keepAlive: true)
AccountBootPort accountBootPort(Ref ref, List<Client> clients) =>
    ClientAccountBootPort(
      repository: ref.watch(accountRepositoryImplProvider),
      clients: clients,
    );
