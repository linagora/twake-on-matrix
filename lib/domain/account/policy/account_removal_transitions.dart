import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/policy/account_policy.dart';
import 'package:twake_chat/domain/account/policy/account_transition_support.dart';

/// The transitions that take an account out of use.
abstract final class AccountRemovalTransitions {
  /// Removes [id] while other accounts remain. Removing a non-active account
  /// never changes the active one; removing the active one picks the next by
  /// [AccountPolicy.nextActiveAfterRemoving], and with no logged-in account
  /// left nobody is logged in ([NoAccount], which keeps the accounts that wait
  /// for their removal). The only account goes through [logoutLast]. An
  /// account that waits for its removal is removed from [NoAccount] too.
  static AccountsState remove(AccountsState state, String id) {
    if (!AccountTransitionSupport.has(state.accounts, id)) {
      throw UnknownAccountException(id);
    }
    if (state is NoAccount) {
      return NoAccount(
        candidateId: state.candidateId,
        accounts: state.accounts.where((a) => a.id != id).toList(),
      );
    }
    if (state is! Active || state.accounts.length < 2) {
      throw AccountTransitionSupport.invalid('remove', state);
    }
    final remaining = state.accounts.where((a) => a.id != id).toList();
    return _withoutActive(state, id, remaining);
  }

  /// Keeps [id], whose removal failed, in the list as unavailable: it cannot
  /// be switched to. When it was the active account the next logged-in one
  /// becomes active in the same emission; with none left nobody is logged in
  /// ([NoAccount], which lists [id] as unavailable). Holding an account that
  /// is already unavailable changes nothing.
  static AccountsState markUnavailable(AccountsState state, String id) {
    if (!AccountTransitionSupport.has(state.accounts, id)) {
      throw UnknownAccountException(id);
    }
    if (state is NoAccount) return state;
    if (state is! Active) {
      throw AccountTransitionSupport.invalid('markUnavailable', state);
    }
    final accounts = [
      for (final a in state.accounts)
        a.id == id ? a.withStatus(AccountStatus.unavailable) : a,
    ];
    return _withoutActive(state, id, accounts);
  }

  /// The last logged-in account logs out but stays, marked logged out, so the
  /// next login can reuse it. The accounts that wait for their removal stay
  /// listed beside it ([NoAccount]); with none, it is [LastLoggedOut].
  static AccountsState logoutLast(AccountsState state) {
    if (state is! Active) {
      throw AccountTransitionSupport.invalid('logoutLast', state);
    }
    final others = state.accounts.where((a) => a.id != state.activeId);
    final loggedOut = state.accounts
        .firstWhere((a) => a.id == state.activeId)
        .withStatus(AccountStatus.loggedOut);
    if (others.isEmpty) return LastLoggedOut(account: loggedOut);
    if (others.any((a) => a.status != AccountStatus.unavailable)) {
      throw AccountTransitionSupport.invalid('logoutLast', state);
    }
    return NoAccount(candidateId: loggedOut.id, accounts: others.toList());
  }

  /// [accounts] is the list after [id] stopped being usable: the active
  /// account stays unless it is [id], then the next usable one takes over.
  static AccountsState _withoutActive(
    Active state,
    String id,
    List<Account> accounts,
  ) {
    if (id != state.activeId) {
      return Active(accounts: accounts, activeId: state.activeId);
    }
    final nextId = _nextUsable(state.accounts, id);
    if (nextId == null) return AccountTransitionSupport.noSurvivor(accounts);
    return Active(accounts: accounts, activeId: nextId);
  }

  /// The account that becomes active when [id] stops being it: the next one
  /// that is logged in, by [AccountPolicy.nextActiveAfterRemoving].
  static String? _nextUsable(List<Account> accounts, String id) =>
      AccountPolicy.nextActiveAfterRemoving(
        ids: [
          for (final a in accounts)
            if (a.isLoggedIn || a.id == id) a.id,
        ],
        removedId: id,
      );
}
