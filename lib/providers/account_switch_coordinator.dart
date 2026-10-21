import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/entities/switch_ticket.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/providers/accounts_provider.dart';

/// What the app does when an account becomes the active one. The coordinator
/// owns the order, the stale-switch guard and the error policy; an
/// implementation owns the body of each step.
///
/// A step that catches its own errors never ends the switch (ToM set-up,
/// persisting the active account, the user info); every other step lets its
/// error through, which ends the switch with a failure.
///
/// A step that awaits and then writes shared state (interceptors, locale, the
/// persisted account) checks its [SwitchToken] right before each write and
/// after every await that comes before one: the coordinator can only check
/// between steps.
abstract class AccountSwitchEffects {
  void createVoipPlugin();
  Future<void> setUpToM(Client client, SwitchToken token);
  Future<void> persistActiveAccount(Client client, SwitchToken token);
  Future<void> loadUserInfo(Client client, SwitchToken token);
  Future<void> loadHomeserverInfo(Client client, SwitchToken token);
  void refreshContacts(Client client);
  void createSupportChat(Client client);
  void listenPresence(Client client);
  void configureSentryUser(Client client);
}

/// Tells one run of the effects whether it is still the newest one. It turns
/// stale as soon as another run starts, the coordinator is disposed, or the
/// switch it belongs to is cancelled.
class SwitchToken {
  SwitchToken._(this._coordinator) : _generation = _coordinator._generation;

  final AccountSwitchCoordinator _coordinator;
  final int _generation;

  bool get isCurrent => _coordinator._generation == _generation;
}

/// Runs the side effects of `Switching` and ends the switch through the
/// notifier (`completeSwitch`, or `failSwitch` when a step throws).
class AccountSwitchCoordinator {
  AccountSwitchCoordinator({
    required AccountSwitchEffects effects,
    required Accounts accounts,
    required Client? Function(String id) clientOf,
    required AccountsState Function() currentState,
  }) : _effects = effects,
       _accounts = accounts,
       _clientOf = clientOf,
       _currentState = currentState;

  final AccountSwitchEffects _effects;
  final Accounts _accounts;
  final Client? Function(String id) _clientOf;
  final AccountsState Function() _currentState;

  void Function()? _unregister;
  Client? _target;
  int _generation = 0;

  /// The client the shared state is configured for; null while a run changes
  /// it and after a run that did not reach its end.
  Client? _appliedFor;

  /// True from the start of a run until one reaches its end: the shared state
  /// may hold a half-applied account.
  bool _dirty = false;

  /// True when the account that was active before the running switch had its
  /// effects applied: only then is there a configuration to put back.
  bool _originApplied = false;

  Future<bool>? _inFlight;
  Client? _inFlightFor;

  /// True once the effects of the active account ran to their end and no run
  /// has started since.
  bool get hasApplied => _appliedFor != null;

  bool isAppliedTo(Client client) => identical(_appliedFor, client);

  /// The account whose effects are running, or null when none are. Until they
  /// end, the active account is still the one being left (P4).
  Client? get target => _target;

  /// Declares this coordinator as the one that ends every switch. Call
  /// [onAccountsChanged] for each state change of `accountsProvider`.
  void start() => _unregister ??= _accounts.registerSwitchHandler();

  void dispose() {
    _unregister?.call();
    _unregister = null;
    _invalidate();
  }

  Future<void> onAccountsChanged(
    AccountsState? previous,
    AccountsState next,
  ) async {
    if (next is LastLoggedOut || next is NoAccount) _reset();
    if (_switchEndedElsewhere(previous, next)) {
      _invalidate();
      _restoreOrigin((next as Active).activeId);
    }
    if (next is! Switching) return;
    if (previous is! Switching) _noteOrigin(next.from);
    await _runSwitch(next);
  }

  /// A switch ended on another account than the one it was heading to.
  bool _switchEndedElsewhere(AccountsState? previous, AccountsState next) =>
      switch ((previous, next)) {
        (Switching(:final to), Active(:final activeId)) => activeId != to,
        _ => false,
      };

  void _noteOrigin(String fromId) {
    final origin = _clientOf(fromId);
    _originApplied = origin != null && isAppliedTo(origin);
  }

  Future<void> _runSwitch(Switching switching) async {
    final ticket = switching.ticket;
    try {
      final client = _clientOf(switching.to);
      if (client == null) throw UnknownAccountException(switching.to);
      await apply(client);
      _accounts.completeSwitch(ticket);
    } catch (e, s) {
      Logs().wtf('AccountSwitchCoordinator: switch failed', e, s);
      _accounts.failSwitch(ticket, e, s);
    }
  }

  /// The effects of [client] becoming active, in the order they always ran. A
  /// newer call takes over [target] and turns the token of this one stale; the
  /// older one stops at its next checkpoint, after the steps that await.
  /// Returns true only when it ran to the end as the newest call.
  Future<bool> apply(Client client) {
    final token = _begin(client);
    final run = _run(client, token);
    _inFlight = run;
    _inFlightFor = client;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) {
        _inFlight = null;
        _inFlightFor = null;
      }
    });
  }

  /// Applies the active account when its effects did not run yet (first login,
  /// boot). Joins a run that is already applying it, waits for a switch that
  /// is running. Returns true when it ran or joined a run that reached its end.
  Future<bool> activateCurrent() async {
    if (_currentState() is Switching) await _accounts.whenSwitchSettled();
    final state = _currentState();
    if (state is! Active) return false;
    final client = _clientOf(state.activeId);
    if (client == null || isAppliedTo(client)) return false;
    final running = _inFlight;
    if (running != null && identical(_inFlightFor, client)) return running;
    return apply(client);
  }

  SwitchToken _begin(Client client) {
    _generation++;
    _target = client;
    _appliedFor = null;
    _dirty = true;
    return SwitchToken._(this);
  }

  void _invalidate() {
    _generation++;
    _target = null;
  }

  /// Nobody is logged in any more: the shared state belongs to no account, so
  /// the next login must apply its effects again.
  void _reset() {
    _invalidate();
    _appliedFor = null;
    _dirty = false;
    _originApplied = false;
    _inFlight = null;
    _inFlightFor = null;
  }

  Future<bool> _run(Client client, SwitchToken token) async {
    try {
      // TODO: Multi-client VoiP support
      _effects.createVoipPlugin();
      await _effects.setUpToM(client, token);
      if (!token.isCurrent) return false;
      await _effects.persistActiveAccount(client, token);
      if (!token.isCurrent) return false;
      await _effects.loadUserInfo(client, token);
      if (!token.isCurrent) return false;
      await _effects.loadHomeserverInfo(client, token);
      if (!token.isCurrent) return false;
      _effects.refreshContacts(client);
      _effects.createSupportChat(client);
      _effects.listenPresence(client);
      _effects.configureSentryUser(client);
      _appliedFor = client;
      _dirty = false;
      return true;
    } finally {
      if (token.isCurrent) _target = null;
    }
  }

  /// After a failed or cancelled switch the shared state may hold the half
  /// applied target; applies the account that stays active again, if its
  /// effects ran before the switch (otherwise there is nothing to put back). Runs in the
  /// background: the caller of the switch must not wait for the network. A
  /// later switch or [activateCurrent] covers a restore that fails.
  void _restoreOrigin(String id) {
    final client = _clientOf(id);
    if (client == null || !_dirty || !_originApplied) return;
    unawaited(
      apply(client).then<void>(
        (_) {},
        onError: (Object e, StackTrace s) =>
            Logs().wtf('AccountSwitchCoordinator: restore failed', e, s),
      ),
    );
  }
}
