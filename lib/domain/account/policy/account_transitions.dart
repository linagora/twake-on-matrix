import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/policy/account_init_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_removal_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_switch_transitions.dart';
import 'package:twake_chat/domain/account/policy/account_transition_support.dart';

/// Pure transitions between [AccountsState]s. Each returns the next state or
/// throws; the input state is never changed. The groups live in
/// [AccountInitTransitions], [AccountSwitchTransitions] and
/// [AccountRemovalTransitions]; this facade is the public entry point.
abstract final class AccountTransitions {
  static AccountsState initialize(
    AccountsState state,
    List<Account> accounts, {
    String? persistedUserId,
  }) => AccountInitTransitions.initialize(
    state,
    accounts,
    persistedUserId: persistedUserId,
  );

  /// Registers a logged-in [account]. After the last logout only that same
  /// account can come back. From [Active] the active account does
  /// not change; follow with [beginSwitch] to make it active. From [NoAccount]
  /// the accounts that wait for their removal stay listed.
  static AccountsState add(AccountsState state, Account account) {
    if (!account.isLoggedIn) {
      throw AccountTransitionSupport.invalid('add', state);
    }
    return switch (state) {
      NoAccount(:final accounts) => Active(
        accounts: [...accounts, account],
        activeId: account.id,
      ),
      Active(:final accounts, :final activeId)
          when !AccountTransitionSupport.has(accounts, account.id) =>
        Active(accounts: [...accounts, account], activeId: activeId),
      LastLoggedOut(account: final last) when last.id == account.id => Active(
        accounts: [account],
        activeId: account.id,
      ),
      _ => throw AccountTransitionSupport.invalid('add', state),
    };
  }

  static AccountsState beginSwitch(
    AccountsState state,
    String toId, {
    int seq = 0,
  }) => AccountSwitchTransitions.beginSwitch(state, toId, seq: seq);

  static AccountsState completeSwitch(AccountsState state, int expectedSeq) =>
      AccountSwitchTransitions.completeSwitch(state, expectedSeq);

  static AccountsState failSwitch(AccountsState state, int expectedSeq) =>
      AccountSwitchTransitions.failSwitch(state, expectedSeq);

  static AccountsState remove(AccountsState state, String id) =>
      AccountRemovalTransitions.remove(state, id);

  static AccountsState markUnavailable(AccountsState state, String id) =>
      AccountRemovalTransitions.markUnavailable(state, id);

  static AccountsState logoutLast(AccountsState state) =>
      AccountRemovalTransitions.logoutLast(state);
}
