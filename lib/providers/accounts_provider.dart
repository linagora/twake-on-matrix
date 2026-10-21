import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';

part 'accounts_provider.g.dart';

/// The only writer of the account state. Every method computes the next state
/// with `AccountTransitions`, writes through the repository, and only then
/// emits it, so a failing write leaves the state as it was.
@Riverpod(keepAlive: true)
class Accounts extends _$Accounts {
  Completer<void>? _pendingSwitch;
  int _switchHandlers = 0;
  int _switchSeq = 0;

  /// Orders the mutations that await the repository, so none of them is
  /// computed from a state that another one is about to replace.
  Future<void> _mutations = Future.value();

  @override
  AccountsState build() => AccountTransitions.initialize(
    const Booting(),
    ref.read(accountRepositoryProvider).registeredAccounts(),
    persistedUserId: ref.read(bootPersistedActiveUserIdProvider),
  );

  /// Registers the account [id] that just logged in. Does nothing when it is
  /// already registered (a repeated `loggedIn` event).
  Future<void> addAccount(String id) => _serialized(() async {
    final listed = state is Active || state is Switching;
    if (listed && state.accounts.any((a) => a.id == id)) return;
    final repository = ref.read(accountRepositoryProvider);
    final account = repository.accountOf(id);
    AccountTransitions.add(state, account);
    await repository.addAccount(account);
    state = AccountTransitions.add(state, account);
  });

  /// The number of the latest switch; the running `Switching` carries it as
  /// `seq`. A handler hands it back to [completeSwitch] or [failSwitch], so
  /// that a stale handler cannot end a newer switch, even one to the same
  /// account.
  int get switchSeq => _switchSeq;

  /// Makes [id] the active account. While the side effects of the switch run
  /// the state is `Switching` and the active account is still the old one.
  /// The returned future ends when `completeSwitch` or `failSwitch` is called
  /// for [id]; without a registered handler it ends at once.
  Future<void> switchTo(String id) async {
    await _mutations;
    final next = AccountTransitions.beginSwitch(state, id, seq: _switchSeq + 1);
    if (identical(next, state)) return;
    if (_isRunningSwitch(next)) {
      // The same switch is already running: wait for it.
      await _pendingSwitch?.future;
      return;
    }
    _supersedePendingSwitch(id);
    if (next is! Switching) {
      state = next;
      return;
    }
    final pending = _pendingSwitch = Completer<void>();
    // Before the emission: a listener may settle the switch synchronously.
    _switchSeq = next.seq;
    state = next;
    if (_switchHandlers == 0) completeSwitch(id, _switchSeq);
    await pending.future;
  }

  bool _isRunningSwitch(AccountsState next) {
    final running = state;
    return next is Switching &&
        running is Switching &&
        next.from == running.from &&
        next.to == running.to;
  }

  /// Ends when the switch that is running now has ended, however it ended.
  Future<void> whenSwitchSettled() async {
    try {
      await _pendingSwitch?.future;
    } catch (_) {}
  }

  /// The running switch to [to] numbered [switchSeq], or null when it is not
  /// the latest one any more.
  Switching? _switchingTo(String to, int switchSeq) {
    final current = state;
    if (current is! Switching) return null;
    if (current.to != to || switchSeq != _switchSeq) return null;
    return current;
  }

  void completeSwitch(String to, int switchSeq) {
    final current = _switchingTo(to, switchSeq);
    if (current == null) return;
    state = AccountTransitions.completeSwitch(current, switchSeq);
    _finishPendingSwitch();
  }

  void failSwitch(
    String to,
    int switchSeq,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final current = _switchingTo(to, switchSeq);
    if (current == null) return;
    state = AccountTransitions.failSwitch(current, switchSeq);
    final pending = _pendingSwitch;
    _pendingSwitch = null;
    pending?.completeError(error, stackTrace);
  }

  /// Removes [id]; when it was the active account the next one becomes active
  /// in the same emission.
  Future<void> removeAccount(String id) => _serialized(() async {
    AccountTransitions.remove(state, id);
    await ref.read(accountRepositoryProvider).removeAccount(id);
    state = AccountTransitions.remove(state, id);
  });

  /// The removal of [id] failed: the account stays listed as unavailable, not
  /// switchable; another logged-in account takes its place when it was the
  /// active one (with none, nobody is logged in). The record that survives a
  /// restart is [recordPendingRemoval], which is retried on its own.
  Future<void> holdRemoval(String id) => _serialized(() async {
    state = AccountTransitions.markUnavailable(state, id);
  });

  /// Records, across restarts, that the removal of [id] is pending.
  Future<void> recordPendingRemoval(String id) => _serialized(
    () => ref.read(accountRepositoryProvider).markRemovalPending(id),
  );

  /// The only account logged out; it stays in the state as `LastLoggedOut`.
  void logoutLast() => state = AccountTransitions.logoutLast(state);

  /// Declares that something reacts to `Switching` and will end it. Returns
  /// the function that unregisters it.
  void Function() registerSwitchHandler() {
    _switchHandlers++;
    var registered = true;
    return () {
      if (!registered) return;
      registered = false;
      _switchHandlers--;
    };
  }

  Future<void> _serialized(Future<void> Function() action) {
    final run = _mutations.then((_) => action());
    _mutations = run.then((_) {}, onError: (_) {});
    return run;
  }

  void _supersedePendingSwitch(String newTarget) {
    final pending = _pendingSwitch;
    _pendingSwitch = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(SwitchSupersededException(newTarget));
    }
  }

  void _finishPendingSwitch() {
    final pending = _pendingSwitch;
    _pendingSwitch = null;
    pending?.complete();
  }
}
