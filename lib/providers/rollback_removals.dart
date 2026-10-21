import 'package:twake_chat/domain/account/repositories/account_repository.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/providers/logout_removal_plan.dart';
import 'package:twake_chat/providers/logout_removals.dart';

/// What a rolled-back login leaves to take away, handed to the removals that
/// retry: a stored account is held as unavailable (not switchable), recorded
/// across restarts and removed again in the background; a candidate that was
/// never stored has its storage deleted again the same way. Both throw while
/// the removal is not done, so the rollback stays unfinished.
class RollbackRemovals {
  RollbackRemovals({
    required AccountRepository repository,
    required Accounts accounts,
    required LogoutRemovals storedRemovals,
    required LogoutRemovals candidateRemovals,
    required bool Function(String id) isActive,
    required Future<void> Function(String id) cancelSubscriptions,
    required ReportFailure report,
  }) : _repository = repository,
       _accounts = accounts,
       _storedRemovals = storedRemovals,
       _candidateRemovals = candidateRemovals,
       _isActive = isActive,
       _cancelSubscriptions = cancelSubscriptions,
       _report = report;

  final AccountRepository _repository;
  final Accounts _accounts;
  final LogoutRemovals _storedRemovals;
  final LogoutRemovals _candidateRemovals;
  final bool Function(String id) _isActive;
  final Future<void> Function(String id) _cancelSubscriptions;
  final ReportFailure _report;

  /// Candidates whose storage is deleted, so a call that follows a retry of
  /// the background finds nothing left to do.
  final Set<String> _discarded = {};

  /// Removes the stored account [id]; [activateReplacement] runs once its
  /// removal (or its hold) changed the account list.
  Future<void> removeStored(
    String id, {
    required Future<void> Function() activateReplacement,
  }) async {
    if (!_repository.registeredAccounts().any((a) => a.id == id)) return;
    final removed = await _storedRemovals.remove(
      id,
      LogoutRemovalPlan(
        id: id,
        accounts: _accounts,
        isActive: () => _isActive(id),
        cancelSubscriptions: () => _cancelSubscriptions(id),
        activateReplacement: activateReplacement,
      ).steps,
      _report,
    );
    if (!removed) throw RemovalPendingException(id);
  }

  /// Deletes the storage of the candidate [id]; a failure is recorded across
  /// restarts and retried.
  Future<void> discardCandidate(String id) async {
    if (_discarded.contains(id)) return;
    final removed = await _candidateRemovals.remove(
      id,
      _discardSteps(id),
      _report,
    );
    if (!removed) throw RemovalPendingException(id);
  }

  /// Runs again, after a restart, the discards that did not finish.
  Future<void> retryRecordedDiscards() async {
    for (final id in await _repository.pendingCandidateDiscards()) {
      await _candidateRemovals.remove(id, _discardSteps(id), _report);
    }
  }

  RemovalSteps _discardSteps(String id) => RemovalSteps(
    remove: () async {
      await _repository.discardCandidate(id);
      _discarded.add(id);
    },
    hold: () async {},
    persist: () => _repository.markCandidateDiscardPending(id),
    settle: () => _repository.clearCandidateDiscardPending(id),
    settleOnHold: false,
  );
}

/// The removal did not work yet; it is held and retried on its own.
class RemovalPendingException implements Exception {
  const RemovalPendingException(this.id);

  final String id;

  @override
  String toString() => 'RemovalPendingException: $id is not removed yet';
}
