import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/policy/account_transition_support.dart';

/// The transitions of an account switch.
class AccountSwitchTransitions {
  const AccountSwitchTransitions(this._support);

  final AccountTransitionSupport _support;

  /// Starts a switch to [toId]. [seq] numbers the switch; its settlement hands
  /// it back to [completeSwitch] or [failSwitch].
  AccountsState beginSwitch(
    AccountsState state,
    String toId, {
    required int seq,
  }) {
    final target = state.accounts.where((a) => a.id == toId).firstOrNull;
    if (target == null) throw UnknownAccountException(toId);
    if (!target.isLoggedIn) {
      throw _support.invalid('beginSwitch', state);
    }
    return switch (state) {
      Active(:final accounts, :final activeId) =>
        toId == activeId
            ? state
            : Switching(accounts: accounts, from: activeId, to: toId, seq: seq),
      Switching(:final accounts, :final from) =>
        toId == from
            ? Active(accounts: accounts, activeId: from)
            : Switching(accounts: accounts, from: from, to: toId, seq: seq),
      Booting() ||
      NoAccount() ||
      LastLoggedOut() => throw _support.invalid('beginSwitch', state),
    };
  }

  /// Ends the switch numbered [expectedSeq]; a [Switching] with another
  /// number is a newer switch and throws [SwitchSupersededException]. A state
  /// that is no longer [Switching] throws [InvalidAccountTransitionException]:
  /// the accounts notifier drops the tickets of ended switches before it calls
  /// here, so only the number check guards a running switch.
  AccountsState completeSwitch(AccountsState state, int expectedSeq) =>
      _settleSwitch(state, expectedSeq, 'completeSwitch', (s) => s.to);

  /// A failed switch goes back to the origin account. Guarded by
  /// [expectedSeq] like [completeSwitch].
  AccountsState failSwitch(AccountsState state, int expectedSeq) =>
      _settleSwitch(state, expectedSeq, 'failSwitch', (s) => s.from);

  /// Ends the switch numbered [expectedSeq] on the account [landOn] picks.
  AccountsState _settleSwitch(
    AccountsState state,
    int expectedSeq,
    String transition,
    String Function(Switching switching) landOn,
  ) {
    if (state is! Switching) {
      throw _support.invalid(transition, state);
    }
    if (state.seq != expectedSeq) throw SwitchSupersededException(state.to);
    return Active(accounts: state.accounts, activeId: landOn(state));
  }
}
