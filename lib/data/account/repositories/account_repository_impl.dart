import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/data/account/datasources/account_client_data_source.dart';
import 'package:twake_chat/data/account/sources/account_client_registry.dart';
import 'package:twake_chat/data/account/sources/pending_removals_source.dart';
import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required AccountClientDataSource dataSource,
    required PersistedActiveAccountSource persistedActiveAccount,
    required PendingRemovalsSource pendingRemovals,
    required PendingRemovalsSource pendingPushRemovals,
    required AccountClientRegistry registry,
    required PendingRemovalsSource pendingCandidateDiscards,
    String Function()? clientNameBuilder,
  }) : _dataSource = dataSource,
       _persistedActiveAccount = persistedActiveAccount,
       _pendingRemovals = pendingRemovals,
       _pendingPushRemovals = pendingPushRemovals,
       _pendingCandidateDiscards = pendingCandidateDiscards,
       _registry = registry,
       _clientNameBuilder = clientNameBuilder;

  final AccountClientDataSource _dataSource;
  final PersistedActiveAccountSource _persistedActiveAccount;
  final PendingRemovalsSource _pendingRemovals;
  final PendingRemovalsSource _pendingPushRemovals;
  final PendingRemovalsSource _pendingCandidateDiscards;
  final AccountClientRegistry _registry;
  final String Function()? _clientNameBuilder;

  /// Names that are in the store, in store order, so a name is never written
  /// twice.
  final Set<String> _storedIds = {};

  /// Accounts whose removal failed, for the synchronous [Account.status]. The
  /// store under [_pendingRemovals] owns them: this copy is set by [adopt] and
  /// then only replaced by what a serialized write stored, never by a read.
  final Set<String> _pendingIds = {};

  /// Until [adopt] ran, the stored ids are not known: the persisted pending
  /// removals are returned as they are, for the boot to pass them to [adopt].
  bool _adopted = false;

  String _newClientName() =>
      _clientNameBuilder?.call() ??
      '${AppConfig.applicationName}-${DateTime.now().microsecondsSinceEpoch}';

  /// Takes over clients that were already created and initialised at boot
  /// (by `ClientManager.getClients`); their names are already in the store.
  /// [pendingRemovals] are the persisted ids read at boot; the ones whose
  /// client is gone are dropped; they leave the store at the next write of
  /// the pending removals. Plain object work: safe to call while the widget
  /// tree is building.
  List<Account> adopt(
    Iterable<Client> clients, {
    required Set<String> pendingRemovals,
  }) {
    _registry.replaceAll(clients);
    _adopted = true;
    _storedIds
      ..clear()
      ..addAll(clients.map((c) => c.clientName));
    _pendingIds
      ..clear()
      ..addAll(pendingRemovals.where(_storedIds.contains))
      ..addAll(_loggedOutBesideOthers(clients));
    return registeredAccounts();
  }

  /// With several accounts, a client that is not logged in is a leftover of a
  /// logout whose cleanup did not finish: it is owed a removal, which the app
  /// runs like any pending one (retried, listed as unavailable meanwhile),
  /// instead of `ClientManager.getClients` deleting it while it loads.
  Set<String> _loggedOutBesideOthers(Iterable<Client> clients) =>
      clients.length > 1
      ? {
          for (final c in clients)
            if (!c.isLogged()) c.clientName,
        }
      : const {};

  @override
  List<Account> registeredAccounts() => [
    for (final id in _storedIds)
      if (_registry[id] case final client?) _toAccount(client),
  ];

  @override
  Account accountOf(String id) => _toAccount(_requireClient(id));

  @override
  Future<Account> createCandidate() async {
    final client = await _dataSource.createClient(_newClientName());
    _registry.add(client);
    return _toAccount(client);
  }

  @override
  Future<void> addAccount(Account account) async {
    _requireClient(account.id);
    if (_storedIds.contains(account.id)) return;
    await _dataSource.addClientName(account.id);
    _storedIds.add(account.id);
  }

  @override
  Future<void> removeAccount(String id) async {
    final client = _requireClient(id);
    if (!_storedIds.contains(id)) throw NotStoredAccountException(id);
    // The storage goes first and the bookkeeping only when that worked, so a
    // failure leaves the account listed and the call can be repeated.
    await _deleteStorage(id, client);
    await _dataSource.removeClientName(id);
    _storedIds.remove(id);
    _registry.remove(id);
    _storageDeleted.remove(id);
    await _forgetPending(id);
  }

  @override
  Future<Set<String>> pendingRemovalIds() async {
    final ids = await _pendingRemovals.read();
    return _adopted ? ids.where(_storedIds.contains).toSet() : ids;
  }

  @override
  Future<void> markRemovalPending(String id) async {
    _requireClient(id);
    if (!_storedIds.contains(id)) throw NotStoredAccountException(id);
    await _updateLivePending((ids) => ids.add(id));
  }

  @override
  Future<Set<String>> pendingPushRemovals() => _pendingPushRemovals.read();

  @override
  Future<void> markPushRemovalPending(String id) =>
      _update(_pendingPushRemovals, (ids) => ids.add(id));

  @override
  Future<void> clearPushRemovalPending(String id) =>
      _update(_pendingPushRemovals, (ids) => ids.remove(id));

  @override
  Future<Set<String>> pendingCandidateDiscards() =>
      _pendingCandidateDiscards.read();

  @override
  Future<void> markCandidateDiscardPending(String id) =>
      _update(_pendingCandidateDiscards, (ids) => ids.add(id));

  @override
  Future<void> clearCandidateDiscardPending(String id) =>
      _update(_pendingCandidateDiscards, (ids) => ids.remove(id));

  /// The end of the last store update; each update starts after it, so two
  /// read-modify-writes never interleave and none is lost.
  Future<void> _lastUpdate = Future.value();

  Future<void> _serialized(Future<void> Function() update) {
    final next = _lastUpdate.then((_) => update());
    _lastUpdate = next.catchError((Object _) {});
    return next;
  }

  /// Reads the store, applies [change] and writes the result, in one
  /// serialized section, so the store stays the only owner of the ids. Marking
  /// or clearing an id twice writes once.
  Future<void> _update(
    PendingRemovalsSource source,
    bool Function(Set<String> ids) change,
  ) => _serialized(() async {
    final ids = await source.read();
    if (change(ids)) await source.write(ids);
  });

  /// Writes the pending account removals with the ones [adopt] found, without
  /// the ids whose client is gone (left by an earlier session), so they are
  /// never written back. [_pendingIds] takes what was written: it is only the
  /// copy the synchronous [Account.status] reads.
  Future<void> _updateLivePending(void Function(Set<String> ids) change) =>
      _serialized(() async {
        final ids = {...await _pendingRemovals.read(), ..._pendingIds}
          ..removeWhere((p) => !_storedIds.contains(p));
        change(ids);
        await _pendingRemovals.write(ids);
        _pendingIds
          ..clear()
          ..addAll(ids);
      });

  /// The account is gone, so it is no longer stored and the update drops it
  /// with any stale id. A record that cannot be cleared now stays in the
  /// store but is ignored by [adopt] and [pendingRemovalIds], and leaves the
  /// store at the next successful write.
  Future<void> _forgetPending(String id) async {
    try {
      await _updateLivePending((ids) => ids.remove(id));
    } catch (e, s) {
      Logs().w('Cannot clear the pending removal of $id', e, s);
    }
  }

  @override
  Future<void> discardCandidate(String id) async {
    // After a restart the candidate has no client yet: one is made on its
    // storage, so the storage can be deleted.
    if (_registry[id] == null &&
        (await _pendingCandidateDiscards.read()).contains(id)) {
      _registry.add(await _dataSource.createClient(id));
    }
    final client = _requireClient(id);
    if (_storedIds.contains(id)) throw StoredAccountException(id);
    await _deleteStorage(id, client);
    _registry.remove(id);
    _storageDeleted.remove(id);
  }

  /// Ids whose client was disposed and whose storage was deleted but whose
  /// bookkeeping is still there: a retry does not dispose them twice.
  final Set<String> _storageDeleted = {};

  Future<void> _deleteStorage(String id, Client client) async {
    if (_storageDeleted.contains(id)) return;
    await _dataSource.disposeAndDeleteStorage(client);
    _storageDeleted.add(id);
  }

  @override
  Future<String?> persistedActiveUserId() => _persistedActiveAccount.read();

  @override
  Future<void> persistActiveAccount(String id) async {
    final userId = _requireClient(id).userID;
    if (userId == null) return;
    await _persistedActiveAccount.write(userId);
  }

  @override
  Future<void> clearPersistedActiveAccount() =>
      _persistedActiveAccount.delete();

  Client _requireClient(String id) =>
      _registry[id] ?? (throw UnknownAccountException(id));

  Account _toAccount(Client client) => Account(
    id: client.clientName,
    userId: client.userID,
    status: _pendingIds.contains(client.clientName)
        ? AccountStatus.unavailable
        : client.isLogged()
        ? AccountStatus.loggedIn
        : AccountStatus.loggedOut,
  );
}
