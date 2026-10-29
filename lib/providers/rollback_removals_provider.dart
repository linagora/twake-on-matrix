import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_services_providers.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';
import 'package:twake_chat/data/account/rollback_removals.dart';

part 'rollback_removals_provider.g.dart';

/// What rolled-back logins leave to take away, retried over the logout and
/// candidate removals; one for the app, so a retry sees every pending one.
@Riverpod(keepAlive: true)
RollbackRemovals rollbackRemovals(Ref ref) => RollbackRemovals(
  repository: ref.read(accountRepositoryProvider),
  accounts: ref.read(accountsProvider.notifier),
  storedRemovals: ref.read(logoutRemovalsProvider),
  candidateRemovals: ref.read(candidateRemovalsProvider),
  isActive: (id) => ref.read(activeMatrixClientProvider)?.clientName == id,
  report: ref.read(reportFailureProvider),
);
