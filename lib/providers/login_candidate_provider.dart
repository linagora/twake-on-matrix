import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/accounts_provider.dart';

part 'login_candidate_provider.g.dart';

/// The id of the client created for "add another account" that has not logged
/// in yet.
@Riverpod(keepAlive: true)
class PendingLoginCandidate extends _$PendingLoginCandidate {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

/// The unlogged `Client` a login screen should use: the placeholder of a
/// logged-out boot, the account that logged out last, else the pending
/// add-account candidate, unless that one has logged in meanwhile. An account
/// that waits for its removal is never it.
///
/// The registry is mutable and does not notify: this recomputes only when
/// `accountsProvider` or `pendingLoginCandidateProvider` emits, so a registry
/// write (a discarded candidate) has to be followed by one of those emissions.
@Riverpod(keepAlive: true)
Client? loginCandidate(Ref ref) {
  final registry = ref.watch(accountClientRegistryProvider);
  Client? clientOf(String? id) => id == null ? null : registry[id];
  final stateClient = clientOf(switch (ref.watch(accountsProvider)) {
    NoAccount(:final candidateId) => candidateId,
    LastLoggedOut(:final account) => account.id,
    _ => null,
  });
  if (stateClient != null) return stateClient;
  final pending = clientOf(ref.watch(pendingLoginCandidateProvider));
  return pending != null && !pending.isLogged() ? pending : null;
}
