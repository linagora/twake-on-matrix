import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/accounts_provider.dart';

part 'active_account_client_provider.g.dart';

/// The Matrix `Client` of the active account; read-only, derived from
/// `accountsProvider`. During a switch it is still the account being left, and
/// it is null when nobody is logged in (`NoAccount`, `LastLoggedOut`).
@Riverpod(keepAlive: true)
Client? activeAccountClient(Ref ref) {
  final id = switch (ref.watch(accountsProvider)) {
    Active(:final activeId) => activeId,
    Switching(:final from) => from,
    _ => null,
  };
  return id == null ? null : ref.watch(accountClientRegistryProvider)[id];
}

/// The `Client` of every account the app lists, in store order. A logged-out
/// boot lists its placeholder and the last logged-out account stays listed;
/// with nobody logged in, the accounts waiting for their removal stay listed
/// too (after the placeholder).
@Riverpod(keepAlive: true)
List<Client> accountClients(Ref ref) {
  final registry = ref.watch(accountClientRegistryProvider);
  final ids = switch (ref.watch(accountsProvider)) {
    Active(:final accounts) ||
    Switching(:final accounts) => [for (final a in accounts) a.id],
    LastLoggedOut(:final account) => [account.id],
    NoAccount(:final candidateId, :final accounts) => [
      ?candidateId,
      for (final a in accounts) a.id,
    ],
    _ => const <String>[],
  };
  return List.unmodifiable([
    for (final id in ids)
      if (registry[id] != null) registry[id]!,
  ]);
}
