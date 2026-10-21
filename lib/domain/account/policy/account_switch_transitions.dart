import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/policy/account_transition_support.dart';

/// The transitions of an account switch.
abstract final class AccountSwitchTransitions {
  /// Starts a switch to [toId]. [seq] numbers the switch; its settlement hands
  /// it back to [completeSwitch] or [failSwitch].
  static AccountsState beginSwitch(
    AccountsState state,
    String toId, {
    int seq = 0,
  }) {
    final target = state.accounts.where((a) => a.id == toId).firstOrNull;
    if (target == null) throw UnknownAccountException(toId);
    if (!target.isLoggedIn) {
      throw AccountTransitionSupport.invalid('beginSwitch', state);
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
      _ => throw AccountTransitionSupport.invalid('beginSwitch', state),
    };
  }

  /// Ends the switch numbered [expectedSeq]; a [Switching] with another
  /// number is a newer switch and throws [SwitchSupersededException].
  static AccountsState completeSwitch(AccountsState state, int expectedSeq) =>
      _settleSwitch(state, expectedSeq, 'completeSwitch', (s) => s.to);

  /// A failed switch goes back to the origin account. Guarded by
  /// [expectedSeq] like [completeSwitch].
  static AccountsState failSwitch(AccountsState state, int expectedSeq) =>
      _settleSwitch(state, expectedSeq, 'failSwitch', (s) => s.from);

  /// Ends the switch numbered [expectedSeq] on the account [landOn] picks.
  static AccountsState _settleSwitch(
    AccountsState state,
    int expectedSeq,
    String transition,
    String Function(Switching switching) landOn,
  ) {
    if (state is! Switching) {
      throw AccountTransitionSupport.invalid(transition, state);
    }
    if (state.seq != expectedSeq) throw SwitchSupersededException(state.to);
    return Active(accounts: state.accounts, activeId: landOn(state));
  }
}
