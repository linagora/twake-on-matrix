import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/entities/switch_ticket.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/providers/account_repository_provider.dart';
import 'package:twake_chat/providers/account_switch_effects_provider.dart';
import 'package:twake_chat/providers/accounts_provider.dart';
import 'package:twake_chat/utils/offline_failure.dart';

part 'account_switch_coordinator.g.dart';

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

/// What the shared state holds, as one value: a combination that cannot
/// happen cannot be built. A run moves it from [_NotApplied] or [_Applied] to
/// [_Applying], and from there to [_Applied] or [_Interrupted]; a logout of
/// the last account moves it back to [_NotApplied].
sealed class _Effects {
  const _Effects();
}

/// Nothing is applied: at boot, and after the last account logged out. The
/// shared state belongs to no account.
final class _NotApplied extends _Effects {
  const _NotApplied();
}

/// The effects of [client] are running. [token] turns stale when another run
/// starts, the coordinator is disposed or the switch is cancelled; a stale run
/// stops at its next checkpoint but keeps this state until it ends.
final class _Applying extends _Effects {
  _Applying(this.client, this.token);

  final Client client;
  final SwitchToken token;

  /// The run itself, for a caller that wants to join it; set right after it
  /// starts.
  Future<bool>? run;
}

/// The effects of [client] ran to their end and no run has started since.
final class _Applied extends _Effects {
  const _Applied(this.client);

  final Client client;
}

/// A run ended without reaching its end (a step failed, or it was replaced
/// and stopped): the shared state may hold a half-applied account.
final class _Interrupted extends _Effects {
  const _Interrupted();
}

/// The one coordinator of the app. Read it once at boot, after
/// `accountSwitchEffectsHolderProvider` is set: until it is read no switch
/// handler is registered and a switch ends at once, with no effects.
@Riverpod(keepAlive: true)
AccountSwitchCoordinator accountSwitchCoordinator(Ref ref) =>
    AccountSwitchCoordinator(ref);

/// Runs the side effects of `Switching` and ends the switch through the
/// notifier (`completeSwitch`, or `failSwitch` when a step throws). It
/// registers the switch handler and listens to `accountsProvider` when it is
/// created, and stops both when its provider is disposed. The effects are the
/// ones `accountSwitchEffectsHolderProvider` holds when a run starts; a run
/// without effects fails.
class AccountSwitchCoordinator {
  AccountSwitchCoordinator(Ref ref, {Client? Function(String id)? clientOf})
    : _ref = ref,
      _clientOf =
          clientOf ?? ((id) => ref.read(accountClientRegistryProvider)[id]) {
    start();
    _subscription = ref.listen(accountsProvider, onAccountsChanged);
    ref.onDispose(dispose);
  }

  final Ref _ref;
  final Client? Function(String id) _clientOf;
  ProviderSubscription<AccountsState>? _subscription;

  Accounts get _accounts => _ref.read(accountsProvider.notifier);

  AccountsState _currentState() => _ref.read(accountsProvider);

  AccountSwitchEffects _readEffects() {
    final effects = _ref.read(accountSwitchEffectsHolderProvider);
    if (effects == null) throw StateError('No account switch effects set');
    return effects;
  }

  void Function()? _unregister;
  bool _disposed = false;
  int _generation = 0;

  /// What the shared state (interceptors, locale, persisted account) holds.
  _Effects _effects = const _NotApplied();

  /// True when the account that was active before the running switch had its
  /// effects applied: only then is there a configuration to put back.
  bool _originApplied = false;

  /// True once the effects of the active account ran to their end and no run
  /// has started since.
  bool get hasApplied => _effects is _Applied;

  bool isAppliedTo(Client client) => switch (_effects) {
    _Applied(client: final applied) => identical(applied, client),
    _ => false,
  };

  /// The account whose effects are running, or null when none are. Until they
  /// end, the active account is still the one being left.
  Client? get target => switch (_effects) {
    _Applying(:final client, :final token) when token.isCurrent => client,
    _ => null,
  };

  /// A run started and none reached its end since: the shared state may hold a
  /// half-applied account.
  bool get _mayBeHalfApplied => switch (_effects) {
    _Applying() || _Interrupted() => true,
    _NotApplied() || _Applied() => false,
  };

  /// Declares this coordinator as the one that ends every switch. Call
  /// [onAccountsChanged] for each state change of `accountsProvider`.
  void start() => _unregister ??= _accounts.registerSwitchHandler();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _subscription?.close();
    _subscription = null;
    _unregister?.call();
    _unregister = null;
    _invalidate();
  }

  Future<void> onAccountsChanged(
    AccountsState? previous,
    AccountsState next,
  ) async {
    if (_disposed) return;
    if (next is LastLoggedOut || next is NoAccount) _reset();
    final endedOn = _switchEndedElsewhere(previous, next);
    if (endedOn != null) {
      _invalidate();
      _restoreOrigin(endedOn);
    }
    if (next is! Switching) return;
    if (previous is! Switching) _noteOrigin(next.from);
    await _runSwitch(next);
  }

  /// The account a switch ended on when it is not the one it was heading to.
  String? _switchEndedElsewhere(AccountsState? previous, AccountsState next) =>
      switch ((previous, next)) {
        (Switching(:final to), Active(:final activeId)) when activeId != to =>
          activeId,
        _ => null,
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
      if (!await apply(client)) {
        throw SwitchSupersededException(switching.to);
      }
      _accounts.completeSwitch(ticket);
    } catch (e, s) {
      _logSwitchError(e, s);
      _accounts.failSwitch(ticket, e, s);
    }
  }

  /// A replaced switch is expected and a lost connection is not a bug: only
  /// the other errors are reported as a failure.
  void _logSwitchError(Object e, StackTrace s) {
    if (e is SwitchSupersededException) {
      Logs().d('AccountSwitchCoordinator: a switch was replaced');
      return;
    }
    if (warnIfOffline(
      e,
      s,
      'AccountSwitchCoordinator: switch failed, offline',
    )) {
      return;
    }
    Logs().wtf('AccountSwitchCoordinator: switch failed', e, s);
  }

  /// The effects of [client] becoming active, in the order they always ran. A
  /// newer call takes over [target] and turns the token of this one stale; the
  /// older one stops at its next checkpoint, after the steps that await.
  /// Returns true only when it ran to the end as the newest call.
  Future<bool> apply(Client client) {
    if (_disposed) return Future.value(false);
    final applying = _begin(client);
    return applying.run = _run(applying);
  }

  /// Applies the active account when its effects did not run yet (first login,
  /// boot). Joins a run that is already applying it and is still the newest
  /// one, and waits for a switch that is running. A run whose token was
  /// cancelled is not reused: a fresh one is started. Returns true when it
  /// ran or joined a run that reached its end.
  Future<bool> activateCurrent() async {
    if (_currentState() is Switching) await _accounts.whenSwitchSettled();
    final state = _currentState();
    if (state is! Active) return false;
    final client = _clientOf(state.activeId);
    if (client == null || isAppliedTo(client)) return false;
    final current = _effects;
    if (current is _Applying &&
        identical(current.client, client) &&
        current.token.isCurrent) {
      final run = current.run;
      if (run != null) return run;
    }
    return apply(client);
  }

  _Applying _begin(Client client) {
    _generation++;
    final applying = _Applying(client, SwitchToken._(this));
    _effects = applying;
    return applying;
  }

  /// Turns the token of the running apply, if any, stale. The run keeps the
  /// state until it stops at its next checkpoint.
  void _invalidate() => _generation++;

  /// Nobody is logged in any more: the shared state belongs to no account, so
  /// the next login must apply its effects again.
  void _reset() {
    _invalidate();
    _effects = const _NotApplied();
    _originApplied = false;
  }

  Future<bool> _run(_Applying applying) async {
    final client = applying.client;
    final token = applying.token;
    try {
      final effects = _readEffects();
      // VoIP is not supported yet: `createVoipPlugin` is an empty stub, so
      // running it on every apply is harmless.
      effects.createVoipPlugin();
      await effects.setUpToM(client, token);
      if (!token.isCurrent) return false;
      await effects.persistActiveAccount(client, token);
      if (!token.isCurrent) return false;
      await effects.loadUserInfo(client, token);
      if (!token.isCurrent) return false;
      await effects.loadHomeserverInfo(client, token);
      if (!token.isCurrent) return false;
      effects.refreshContacts(client);
      effects.createSupportChat(client);
      effects.listenPresence(client);
      effects.configureSentryUser(client);
      _effects = _Applied(client);
      return true;
    } finally {
      // A run that did not reach its end leaves the shared state half applied.
      // Only the run that still holds the state ends it: a newer run or a
      // reset already replaced it.
      if (identical(_effects, applying)) _effects = const _Interrupted();
    }
  }

  /// After a failed or cancelled switch the shared state may hold the half
  /// applied target; applies the account that stays active again, if its
  /// effects ran before the switch (otherwise there is nothing to put back).
  /// Runs in the background: the caller of the switch must not wait for the
  /// network. A later switch or [activateCurrent] covers a restore that fails.
  void _restoreOrigin(String id) {
    final client = _clientOf(id);
    if (client == null || !_mayBeHalfApplied || !_originApplied) return;
    unawaited(
      apply(client).then<void>(
        (_) {},
        onError: (Object e, StackTrace s) =>
            Logs().w('AccountSwitchCoordinator: restore failed', e, s),
      ),
    );
  }
}
