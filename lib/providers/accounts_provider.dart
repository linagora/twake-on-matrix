import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:matrix/matrix.dart' show Logs;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/entities/switch_ticket.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/policy/account_transitions.dart';
import 'package:twake_chat/providers/account_boot_snapshot_provider.dart';
import 'package:twake_chat/providers/account_usecase_providers.dart';
import 'package:twake_chat/providers/account_transitions_provider.dart';

part 'accounts_provider.g.dart';

/// The only writer of the account state. Every method computes the next state
/// with `AccountTransitions`, writes through the repository, and only then
/// emits it, so a failing write leaves the state as it was.
@Riverpod(keepAlive: true)
class Accounts extends _$Accounts {
  Completer<void>? _pendingSwitch;
  bool _hasSwitchHandler = false;
  int _switchSeq = 0;

  AccountTransitions get _transitions => ref.read(accountTransitionsProvider);

  /// Orders the mutations that await the repository, so none of them is
  /// computed from a state that another one is about to replace.
  Future<void> _mutations = Future.value();

  /// The boot clients are adopted here, so nothing has to adopt them before
  /// the state is first read.
  @override
  AccountsState build() {
    final boot = ref.watch(bootAccountSnapshotProvider);
    ref
        .watch(adoptBootAccountsUseCaseProvider)
        .execute(pendingRemovals: boot.pendingRemovalIds);
    return ref
        .watch(initializeAccountsUseCaseProvider)
        .execute(persistedUserId: boot.persistedActiveUserId);
  }

  /// Registers the account [id] that just logged in. Does nothing when it is
  /// already registered (a repeated `loggedIn` event).
  Future<void> addAccount(AccountId id) => _serialized(() async {
    final next = await ref
        .read(addAccountUseCaseProvider)
        .execute(() => state, id.value);
    if (next != null && ref.mounted) state = next;
  });

  /// The number of the latest switch; the running `Switching` carries it as
  /// `seq`. A handler hands its [SwitchTicket] back to [completeSwitch] or
  /// [failSwitch], so that a stale handler cannot end a newer switch, even one
  /// to the same account.
  @visibleForTesting
  int get switchSeq => _switchSeq;

  /// Makes [id] the active account. While the side effects of the switch run
  /// the state is `Switching` and the active account is still the old one.
  /// The returned future ends when `completeSwitch` or `failSwitch` is called
  /// for [id]. It completes normally when the switch is completed and throws
  /// the error of `failSwitch`, or [SwitchSupersededException] when a newer
  /// switch replaces it: callers have to catch it. Without a registered
  /// handler it ends at once, with none of the side effects of the switch.
  Future<void> switchTo(AccountId id) async {
    await _mutations;
    final next = _transitions.beginSwitch(state, id.value, seq: _switchSeq + 1);
    if (identical(next, state)) return;
    if (_isRunningSwitch(next)) {
      // The same switch is already running: wait for it.
      await _pendingSwitch?.future;
      return;
    }
    _supersedePendingSwitch(SwitchSupersededException(id.value));
    if (next is! Switching) {
      state = next;
      return;
    }
    final pending = _pendingSwitch = Completer<void>();
    // Before the emission: a listener may settle the switch synchronously.
    _switchSeq = next.seq;
    state = next;
    if (!_hasSwitchHandler) {
      Logs().w(
        'Switch to ${id.value} has no handler: it ends without its side effects',
      );
      completeSwitch(next.ticket);
    }
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

  /// The running switch that [ticket] names, or null when it is not the
  /// latest one any more.
  Switching? _switchingTo(SwitchTicket ticket) {
    final current = state;
    if (current is! Switching) return null;
    if (current.to != ticket.to || ticket.seq != _switchSeq) return null;
    return current;
  }

  void completeSwitch(SwitchTicket ticket) {
    final current = _switchingTo(ticket);
    if (current == null) return;
    state = _transitions.completeSwitch(current, ticket.seq);
    _finishPendingSwitch();
  }

  void failSwitch(SwitchTicket ticket, Object error, [StackTrace? stackTrace]) {
    final current = _switchingTo(ticket);
    if (current == null) return;
    state = _transitions.failSwitch(current, ticket.seq);
    final pending = _pendingSwitch;
    _pendingSwitch = null;
    pending?.completeError(error, stackTrace);
  }

  /// Removes [id]; when it was the active account the next one becomes active
  /// in the same emission.
  Future<void> removeAccount(AccountId id) => _serialized(() async {
    final next = await ref
        .read(removeAccountUseCaseProvider)
        .execute(() => state, id.value);
    if (ref.mounted) state = next;
  });

  /// The removal of [id] failed: the account stays listed as unavailable, not
  /// switchable; another logged-in account takes its place when it was the
  /// active one (with none, nobody is logged in). The record that survives a
  /// restart is [recordPendingRemoval], which is retried on its own.
  Future<void> holdRemoval(AccountId id) => _serialized(() async {
    state = _transitions.markUnavailable(state, id.value);
  });

  /// Records, across restarts, that the removal of [id] is pending.
  Future<void> recordPendingRemoval(AccountId id) => _serialized(
    () => ref.read(recordPendingRemovalUseCaseProvider).execute(id.value),
  );

  /// The only account logged out; it stays in the state as `LastLoggedOut`.
  void logoutLast() => state = _transitions.logoutLast(state);

  /// Declares that something reacts to `Switching` and will end it: the
  /// coordinator, which is the only one. Returns the function that unregisters
  /// it.
  void Function() registerSwitchHandler() {
    assert(!_hasSwitchHandler, 'a switch handler is already registered');
    _hasSwitchHandler = true;
    var registered = true;
    return () {
      if (!registered) return;
      registered = false;
      _hasSwitchHandler = false;
    };
  }

  Future<void> _serialized(Future<void> Function() action) {
    final run = _mutations.then((_) => action());
    _mutations = run.then((_) {}, onError: (_) {});
    return run;
  }

  void _supersedePendingSwitch(SwitchSupersededException error) {
    final pending = _pendingSwitch;
    _pendingSwitch = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(error);
    }
  }

  void _finishPendingSwitch() {
    final pending = _pendingSwitch;
    _pendingSwitch = null;
    pending?.complete();
  }
}
