import 'package:flutter/foundation.dart' show listEquals;
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.provider.dart';
import 'package:twake_chat/providers/accounts_provider.dart';

part 'active_matrix_client_provider.g.dart';

/// The Matrix `Client` of the active account; read-only, derived from
/// `accountsProvider`. The registry it reads does not notify, so it recomputes
/// only when `accountsProvider` emits. During a switch it is still the account being left, and
/// it is null when nobody is logged in (`NoAccount`, `LastLoggedOut`).
@Riverpod(keepAlive: true)
Client? activeMatrixClient(Ref ref) {
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
///
/// The registry is mutable and does not notify: this recomputes only when
/// `accountsProvider` emits, so every registry write has to be followed by an
/// emission. It notifies only when the clients themselves changed, not on
/// `Active -> Switching -> Active` around the same ones.
@Riverpod(keepAlive: true)
class AccountClients extends _$AccountClients {
  @override
  List<Client> build() {
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
    return List.unmodifiable([for (final id in ids) ?registry[id]]);
  }

  @override
  bool updateShouldNotify(List<Client> previous, List<Client> next) =>
      !listEquals(previous, next);
}
