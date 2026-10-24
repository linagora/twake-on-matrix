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
class AccountTransitions {
  const AccountTransitions({
    required AccountInitTransitions init,
    required AccountSwitchTransitions switching,
    required AccountRemovalTransitions removal,
    required AccountTransitionSupport support,
  }) : _init = init,
       _switching = switching,
       _removal = removal,
       _support = support;

  final AccountInitTransitions _init;
  final AccountSwitchTransitions _switching;
  final AccountRemovalTransitions _removal;
  final AccountTransitionSupport _support;

  AccountsState initialize(
    AccountsState state,
    List<Account> accounts, {
    String? persistedUserId,
  }) => _init.initialize(state, accounts, persistedUserId: persistedUserId);

  /// Registers a logged-in [account]. After the last logout only that same
  /// account can come back. From [Active] the active account does
  /// not change; follow with [beginSwitch] to make it active. From [NoAccount]
  /// the accounts that wait for their removal stay listed.
  AccountsState add(AccountsState state, Account account) {
    if (!account.isLoggedIn) {
      throw _support.invalid('add', state);
    }
    return switch (state) {
      NoAccount(:final accounts) when !_support.has(accounts, account.id) =>
        Active(accounts: [...accounts, account], activeId: account.id),
      Active(:final accounts, :final activeId)
          when !_support.has(accounts, account.id) =>
        Active(accounts: [...accounts, account], activeId: activeId),
      LastLoggedOut(account: final last) when last.id == account.id => Active(
        accounts: [account],
        activeId: account.id,
      ),
      _ => throw _support.invalid('add', state),
    };
  }

  AccountsState beginSwitch(
    AccountsState state,
    String toId, {
    required int seq,
  }) => _switching.beginSwitch(state, toId, seq: seq);

  AccountsState completeSwitch(AccountsState state, int expectedSeq) =>
      _switching.completeSwitch(state, expectedSeq);

  AccountsState failSwitch(AccountsState state, int expectedSeq) =>
      _switching.failSwitch(state, expectedSeq);

  AccountsState remove(AccountsState state, String id) =>
      _removal.remove(state, id);

  AccountsState markUnavailable(AccountsState state, String id) =>
      _removal.markUnavailable(state, id);

  AccountsState logoutLast(AccountsState state) => _removal.logoutLast(state);
}
