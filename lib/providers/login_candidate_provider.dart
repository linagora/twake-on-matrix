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
/// add-account candidate. An account that waits for its removal is never it.
@Riverpod(keepAlive: true)
Client? loginCandidate(Ref ref) {
  final registry = ref.watch(accountClientRegistryProvider);
  final state = ref.watch(accountsProvider);
  if (state is NoAccount && state.candidateId != null) {
    final placeholder = registry[state.candidateId!];
    if (placeholder != null) return placeholder;
  }
  if (state is LastLoggedOut) {
    final loggedOut = registry[state.account.id];
    if (loggedOut != null) return loggedOut;
  }
  final pending = ref.watch(pendingLoginCandidateProvider);
  return pending == null ? null : registry[pending];
}
