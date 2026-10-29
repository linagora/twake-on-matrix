import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/data/account/login_host.dart';

import 'fakes.dart';

/// A host that records every call. A step can be held on a gate (to put two
/// operations in a race) or made to throw; both are keyed by the name the step
/// is recorded under, for example `tom:c1`.
class FakeLoginHost implements LoginHost {
  final calls = <String>[];
  final events = <ClientLoginStateEvent>[];
  final reports = <String>[];
  final failing = <String>{};
  final gates = <String, Completer<void>>{};
  final stored = <String>{};
  final loggedIn = <String>{'a'};
  final streams = <String, StreamController<LoginState>>{};
  final clients = <String, FakeAccountClient>{};
  final _listens = <String, int>{};
  final _cancels = <String, int>{};

  /// Listeners still attached for [id]. A replaced session that leaks its
  /// watch leaves this above the one listener of the session that replaced it.
  int openListeners(String id) => (_listens[id] ?? 0) - (_cancels[id] ?? 0);

  /// Holds the retry of the pending removals until it completes.
  Completer<void>? removalGate;

  bool switchSucceeds = true;
  Client? reusable;
  String? activeName = 'a';
  String? pending;
  int _created = 0;

  /// The name the next candidate gets.
  String get nextCandidate => 'c${_created + 1}';

  FakeAccountClient clientOf(String id) =>
      clients.putIfAbsent(id, () => FakeAccountClient(id, userID: '@$id:s'));

  Future<void> _step(String name) async {
    calls.add(name);
    await gates[name]?.future;
    if (failing.contains(name)) throw StateError('$name failed');
  }

  @override
  bool isStored(AccountId id) => stored.contains(id.value);

  @override
  bool isLoggedIn(AccountId id) => loggedIn.contains(id.value);

  @override
  Future<void> addAccount(AccountId id) async {
    await _step('addAccount:${id.value}');
    stored.add(id.value);
  }

  @override
  Future<void> removeAccount(AccountId id) async {
    await _step('removeAccount:${id.value}');
    stored.remove(id.value);
  }

  @override
  void logoutLast() {
    calls.add('logoutLast');
    if (failing.contains('logoutLast')) throw StateError('logoutLast failed');
  }

  @override
  Client get activeClient => clientOf(activeName!);

  @override
  String? get activeClientName => activeName;

  @override
  Client? clientByName(AccountId id) => clients[id.value];

  @override
  Future<bool> switchTo(Client client) async {
    await _step('switchTo:${client.clientName}');
    return switchSucceeds;
  }

  @override
  Future<void> applyEffects(Client client) =>
      _step('apply:${client.clientName}');

  @override
  Future<void> clearEffects() => _step('clearEffects');

  @override
  Future<void> activateCurrent() => _step('activateCurrent');

  @override
  Client? get reusableClient => reusable;

  @override
  Future<Client> createCandidate() async {
    final name = 'c${++_created}';
    await _step('createCandidate:$name');
    return clientOf(name);
  }

  @override
  Future<void> discardCandidate(AccountId id) async {
    await _step('discardCandidate:${id.value}');
  }

  @override
  String? get pendingCandidateId => pending;

  @override
  void setPendingCandidate(AccountId? id) => pending = id?.value;

  @override
  Future<void> signOut(AccountId id, {required bool quiet}) =>
      _step('signOut:$id:${quiet ? 'quiet' : 'loud'}');

  @override
  void forgetQuiet(AccountId id) => calls.add('forgetQuiet:${id.value}');

  @override
  StreamSubscription<LoginState> listenLoginState(
    Client client,
    void Function(LoginState state) onState,
  ) {
    final controller = streams.putIfAbsent(
      client.clientName,
      () => StreamController<LoginState>.broadcast(
        onListen: () => _listens[client.clientName] =
            (_listens[client.clientName] ?? 0) + 1,
        onCancel: () => _cancels[client.clientName] =
            (_cancels[client.clientName] ?? 0) + 1,
      ),
    );
    return controller.stream.listen(onState);
  }

  @override
  Future<void> removePush(AccountId id) => _step('removePush:${id.value}');

  @override
  Future<void> cancelSubscriptions(AccountId id) =>
      _step('cancelSubs:${id.value}');

  @override
  Future<void> registerSubscriptions(AccountId id) =>
      _step('registerSubs:${id.value}');

  @override
  Future<void> setUpToM(Client client) => _step('tom:${client.clientName}');

  @override
  Future<void> setUpFederation(Client client) =>
      _step('federation:${client.clientName}');

  @override
  Future<void> syncRecoveryKey(Client client) =>
      _step('recoveryKey:${client.clientName}');

  @override
  Future<void> setUpAdditionalPush(Client client) =>
      _step('push:${client.clientName}');

  @override
  Future<void> cancelContactSync() => _step('cancelContactSync');

  @override
  void reSyncContacts() => calls.add('reSyncContacts');

  @override
  void markFirstSyncDone() => calls.add('firstSyncDone');

  @override
  void emit(ClientLoginStateEvent event) {
    calls.add('emit:${event.multipleAccountLoginType.name}');
    events.add(event);
    if (failing.contains('emit')) throw StateError('emit failed');
  }

  /// How many times the pending removals of logged-out accounts were retried.
  int removalRetries = 0;

  /// Runs when the removals are retried (a retry can end a session).
  void Function()? onRemovalRetry;

  @override
  Future<void> retryPendingRemovals() async {
    removalRetries++;
    await removalGate?.future;
    await Future<void>.delayed(Duration.zero);
    onRemovalRetry?.call();
  }

  @override
  void report(Object error, StackTrace stackTrace, String what) =>
      reports.add(what);

  /// Sends `loggedIn` on the stream of [id], as the SDK does.
  void logIn(String id) {
    loggedIn.add(id);
    streams[id]!.add(LoginState.loggedIn);
  }
}
