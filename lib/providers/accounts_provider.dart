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
import 'package:twake_chat/data/account/repositories/account_repository_impl.provider.dart';
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

  /// The state of the accounts the repository holds, which has adopted the
  /// boot clients when it was built.
  @override
  AccountsState build() {
    ref.onDispose(_finishPendingSwitch);
    final boot = ref.watch(bootAccountSnapshotProvider);
    return ref
        .watch(initializeAccountsUseCaseProvider)
        .execute(persistedUserId: boot.persistedActiveUserId);
  }

  /// Registers the account [id] that just logged in. Does nothing when it is
  /// already registered (a repeated `loggedIn` event).
  Future<void> addAccount(AccountId id) => _serialized(() async {
    final next = await ref
        .read(addAccountUseCaseProvider)
        .execute(_current, id.value);
    if (next != null) _move(next);
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
    if (!ref.mounted) return;
    final next = _transitions.beginSwitch(state, id.value, seq: _switchSeq + 1);
    if (identical(next, state)) return;
    if (_isRunningSwitch(next)) {
      // The same switch is already running: wait for it.
      await _pendingSwitch?.future;
      return;
    }
    _supersedePendingSwitch(SwitchSupersededException(id.value));
    if (next is! Switching) {
      _move(next);
      return;
    }
    final pending = _pendingSwitch = Completer<void>();
    // Before the emission: a listener may settle the switch synchronously.
    _switchSeq = next.seq;
    _move(next);
    if (!_hasSwitchHandler) {
      Logs().w('A switch has no handler: it ends without its side effects');
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
    if (!ref.mounted) return null;
    final current = state;
    if (current is! Switching) return null;
    if (current.to != ticket.to || ticket.seq != _switchSeq) return null;
    return current;
  }

  void completeSwitch(SwitchTicket ticket) {
    final current = _switchingTo(ticket);
    if (current == null) return;
    _move(_transitions.completeSwitch(current, ticket.seq));
    _finishPendingSwitch();
  }

  void failSwitch(SwitchTicket ticket, Object error, [StackTrace? stackTrace]) {
    final current = _switchingTo(ticket);
    if (current == null) return;
    _move(_transitions.failSwitch(current, ticket.seq));
    final pending = _pendingSwitch;
    _pendingSwitch = null;
    pending?.completeError(error, stackTrace);
  }

  /// Removes [id]; when it was the active account the next one becomes active
  /// in the same emission. Throws [SwitchInProgressException] while a switch
  /// runs, before anything is deleted: wait with [whenSwitchSettled] and ask
  /// again.
  Future<void> removeAccount(AccountId id) => _serialized(() async {
    _rejectDuringSwitch(id);
    final next = await ref
        .read(removeAccountUseCaseProvider)
        .execute(_current, id.value);
    _move(next);
  });

  /// The removal of [id] failed: the account stays listed as unavailable, not
  /// switchable; another logged-in account takes its place when it was the
  /// active one (with none, nobody is logged in). The record that survives a
  /// restart is [recordPendingRemoval], which is retried on its own. Throws
  /// [SwitchInProgressException] while a switch runs.
  Future<void> holdRemoval(AccountId id) => _serialized(() async {
    _rejectDuringSwitch(id);
    _move(_transitions.markUnavailable(_current(), id.value));
  });

  /// Records, across restarts, that the removal of [id] is pending.
  Future<void> recordPendingRemoval(AccountId id) => _serialized(
    () => ref.read(accountRepositoryProvider).markRemovalPending(id.value),
  );

  /// The only account logged out; it stays in the state as `LastLoggedOut`.
  /// Serialized with the writes, so it never changes the state under a removal
  /// that is still waiting on the repository.
  Future<void> logoutLast() => _serialized(() async {
    _move(_transitions.logoutLast(_current()));
  });

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

  /// The only place that writes the state: a container disposed meanwhile
  /// (a write after an `await`) ends the mutation quietly.
  void _move(AccountsState next) {
    if (ref.mounted) state = next;
  }

  /// The state the use cases read after they awaited the repository. A
  /// container disposed meanwhile ends the mutation quietly ([_Disposed]).
  AccountsState _current() {
    if (!ref.mounted) throw const _Disposed();
    return state;
  }

  /// A switch can start after a caller waited for the last one, while its
  /// write is queued behind another mutation; the write finds `Switching` here.
  void _rejectDuringSwitch(AccountId id) {
    if (_current() is Switching) throw SwitchInProgressException(id.value);
  }

  Future<void> _serialized(Future<void> Function() action) {
    final run = _mutations.then((_) => action()).onError<_Disposed>((_, _) {});
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

/// Thrown by [Accounts._current] once the container is disposed, so a mutation
/// that was waiting on the repository stops instead of writing to a dead state.
class _Disposed implements Exception {
  const _Disposed();
}
