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

  /// Accounts whose removal failed. They are persisted, so a restart still
  /// knows them.
  final Set<String> _pendingIds = {};

  String _newClientName() =>
      _clientNameBuilder?.call() ??
      '${AppConfig.applicationName}-${DateTime.now().microsecondsSinceEpoch}';

  /// Takes over clients that were already created and initialised at boot
  /// (by `ClientManager.getClients`); their names are already in the store.
  /// [pendingRemovals] are the persisted ids read at boot; the ones whose
  /// client is gone are dropped. Plain object work: safe to call while the
  /// widget tree is building.
  List<Account> adopt(
    Iterable<Client> clients, {
    Set<String> pendingRemovals = const {},
  }) {
    _registry.replaceAll(clients);
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
      if (_registry[id] != null) _toAccount(_registry[id]!),
  ];

  @override
  Account accountOf(String id) => _toAccount(_requireClient(id));

  @override
  Future<List<Account>> loadAccounts({bool initialize = true}) async {
    final clients = await _dataSource.loadClients(initialize: initialize);
    _registry.replaceAll(clients);
    _storedIds
      ..clear()
      ..addAll(clients.map((c) => c.clientName));
    _pendingIds
      ..clear()
      ..addAll((await _pendingRemovals.read()).where(_storedIds.contains))
      ..addAll(_loggedOutBesideOthers(clients));
    return clients.map(_toAccount).toList();
  }

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
    if (!_storedIds.contains(id)) {
      throw const InvalidAccountTransitionException(
        transition: 'removeAccount',
        stateName: 'candidate',
      );
    }
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
  Future<void> markRemovalPending(String id) async {
    _requireClient(id);
    if (!_storedIds.contains(id)) {
      throw const InvalidAccountTransitionException(
        transition: 'markRemovalPending',
        stateName: 'candidate',
      );
    }
    _pendingIds.add(id);
    await _pendingRemovals.write(_pendingIds);
  }

  @override
  Future<Set<String>> pendingPushRemovals() async {
    _pushIds
      ..clear()
      ..addAll(await _pendingPushRemovals.read());
    return {..._pushIds};
  }

  @override
  Future<void> markPushRemovalPending(String id) async {
    _pushIds.add(id);
    await _pendingPushRemovals.write(_pushIds);
  }

  @override
  Future<void> clearPushRemovalPending(String id) async {
    if (!_pushIds.remove(id)) return;
    await _pendingPushRemovals.write(_pushIds);
  }

  /// Accounts whose pusher deletion failed; persisted like [_pendingIds].
  final Set<String> _pushIds = {};

  @override
  Future<Set<String>> pendingCandidateDiscards() async {
    _candidateIds
      ..clear()
      ..addAll(await _pendingCandidateDiscards.read());
    return {..._candidateIds};
  }

  @override
  Future<void> markCandidateDiscardPending(String id) async {
    _candidateIds.add(id);
    await _pendingCandidateDiscards.write(_candidateIds);
  }

  @override
  Future<void> clearCandidateDiscardPending(String id) async {
    if (!_candidateIds.remove(id)) return;
    await _pendingCandidateDiscards.write(_candidateIds);
  }

  /// Candidates whose storage could not be deleted; persisted, so a restart
  /// still knows them.
  final Set<String> _candidateIds = {};

  /// The account is gone; a record that cannot be cleared now is dropped at the
  /// next boot, because its client is no longer there.
  Future<void> _forgetPending(String id) async {
    if (!_pendingIds.remove(id)) return;
    try {
      await _pendingRemovals.write(_pendingIds);
    } catch (e, s) {
      Logs().w('Cannot clear the pending removal of $id', e, s);
    }
  }

  @override
  Future<void> discardCandidate(String id) async {
    // After a restart the candidate has no client yet: one is made on its
    // storage, so the storage can be deleted.
    if (_registry[id] == null && _candidateIds.contains(id)) {
      _registry.add(await _dataSource.createClient(id));
    }
    final client = _requireClient(id);
    if (_storedIds.contains(id)) {
      throw const InvalidAccountTransitionException(
        transition: 'discardCandidate',
        stateName: 'stored account',
      );
    }
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
