import 'package:twake_chat/domain/account/entities/account.dart';

/// Everything persisted about accounts: the client names in the store, the
/// persisted active account and the storage of a discarded candidate.
/// Accounts are identified by client name; the persisted active account is
/// stored by Matrix user id.
abstract interface class AccountRepository {
  /// The accounts that are stored and in memory, in the order they were
  /// stored.
  List<Account> registeredAccounts();

  /// The account with [id]; throws UnknownAccountException when none.
  Account accountOf(String id);

  /// A new unlogged account that is not stored until [addAccount].
  Future<Account> createCandidate();

  /// Stores the name of [account]; a name already stored is kept once.
  Future<void> addAccount(Account account);

  /// Disposes the client of the stored account [id] and deletes its storage,
  /// then drops the name from the store and the account from memory. Callers
  /// cancel the subscriptions on the client first. A failure leaves the
  /// account as it was and the call can be repeated; storage that was already
  /// deleted is not deleted twice. An account that was never stored is a
  /// candidate: use discardCandidate.
  Future<void> removeAccount(String id);

  /// The ids of the stored accounts whose removal was recorded by
  /// [markRemovalPending] and did not finish, read from the store. An id whose
  /// account is gone is left out.
  Future<Set<String>> pendingRemovalIds();

  /// Records, across restarts, that the removal of the stored account [id]
  /// failed: the account is listed as unavailable until [removeAccount] works.
  /// Throws NotStoredAccountException for a candidate.
  Future<void> markRemovalPending(String id);

  /// The accounts whose pusher deletion failed, kept across restarts: it runs
  /// again while their session is open. Read from the store.
  Future<Set<String>> pendingPushRemovals();

  /// Records that deleting the pusher of [id] failed.
  Future<void> markPushRemovalPending(String id);

  /// Forgets the failed pusher deletion of [id]; does nothing when none.
  Future<void> clearPushRemovalPending(String id);

  /// The candidates of a rolled-back login whose storage could not be deleted,
  /// kept across restarts: [discardCandidate] runs again for them. Read from
  /// the store.
  Future<Set<String>> pendingCandidateDiscards();

  /// Records that deleting the storage of the candidate [id] failed.
  Future<void> markCandidateDiscardPending(String id);

  /// Forgets the failed discard of [id]; does nothing when none.
  /// [discardCandidate] already does it once the storage is deleted.
  Future<void> clearCandidateDiscardPending(String id);

  /// Disposes a candidate that never became an account and deletes its
  /// storage; it stays known until that worked, so a failure can be retried.
  /// A candidate recorded by [markCandidateDiscardPending] is known again
  /// after a restart (read with [pendingCandidateDiscards] first). Once the
  /// storage is deleted the record is cleared too, like [removeAccount] does
  /// for its own: best effort, a record that cannot be cleared does not fail
  /// the call and the discard runs again at the next start.
  /// Throws StoredAccountException for a stored account.
  Future<void> discardCandidate(String id);

  Future<String?> persistedActiveUserId();

  /// Persists the user id of [id]; does nothing while the account has none.
  Future<void> persistActiveAccount(String id);

  Future<void> clearPersistedActiveAccount();
}
