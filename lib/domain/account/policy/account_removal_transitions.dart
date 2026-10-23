import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/policy/account_policy.dart';
import 'package:twake_chat/domain/account/policy/account_transition_support.dart';

/// The transitions that take an account out of use.
class AccountRemovalTransitions {
  const AccountRemovalTransitions(this._policy, this._support);

  final AccountPolicy _policy;
  final AccountTransitionSupport _support;

  /// Removes [id] while other accounts remain. Removing a non-active account
  /// never changes the active one; removing the active one picks the next by
  /// [AccountPolicy.nextActiveAfterRemoving], and with no logged-in account
  /// left nobody is logged in ([NoAccount], which keeps the accounts that wait
  /// for their removal). The only account goes through [logoutLast]. An
  /// account that waits for its removal is removed from [NoAccount] and
  /// [AccountInitFailed] too.
  AccountsState remove(AccountsState state, String id) {
    if (!_support.has(state.accounts, id)) {
      throw UnknownAccountException(id);
    }
    if (state is NoAccount) {
      return NoAccount(
        candidateId: state.candidateId,
        accounts: state.accounts.where((a) => a.id != id).toList(),
      );
    }
    if (state is AccountInitFailed) {
      return AccountInitFailed(
        id: state.id,
        error: state.error,
        accounts: state.accounts.where((a) => a.id != id).toList(),
      );
    }
    if (state is! Active || state.accounts.length < 2) {
      throw _support.invalid('remove', state);
    }
    final remaining = state.accounts.where((a) => a.id != id).toList();
    return _withoutActive(state, id, remaining);
  }

  /// Keeps [id], whose removal failed, in the list as unavailable: it cannot
  /// be switched to. When it was the active account the next logged-in one
  /// becomes active in the same emission; with none left nobody is logged in
  /// ([NoAccount], which lists [id] as unavailable). Holding an account that
  /// is already unavailable changes nothing.
  AccountsState markUnavailable(AccountsState state, String id) {
    if (!_support.has(state.accounts, id)) {
      throw UnknownAccountException(id);
    }
    if (state is NoAccount || state is AccountInitFailed) return state;
    if (state is! Active) {
      throw _support.invalid('markUnavailable', state);
    }
    final accounts = [
      for (final a in state.accounts)
        a.id == id ? a.withStatus(AccountStatus.unavailable) : a,
    ];
    return _withoutActive(state, id, accounts);
  }

  /// The last logged-in account logs out but stays, marked logged out, so the
  /// next login can reuse it. The accounts that wait for their removal stay
  /// listed beside it ([NoAccount]); with none, it is [LastLoggedOut]. Another
  /// logged-in account rejects it; a logged-out or init-failed one beside it
  /// is dropped, as `initialize` does.
  AccountsState logoutLast(AccountsState state) {
    if (state is! Active) {
      throw _support.invalid('logoutLast', state);
    }
    final others = state.accounts.where((a) => a.id != state.activeId);
    final loggedOut = state.accounts
        .firstWhere((a) => a.id == state.activeId)
        .withStatus(AccountStatus.loggedOut);
    if (others.isEmpty) return LastLoggedOut(account: loggedOut);
    if (others.any((a) => a.isLoggedIn)) {
      throw _support.invalid('logoutLast', state);
    }
    return NoAccount(
      candidateId: loggedOut.id,
      accounts: others
          .where((a) => a.status == AccountStatus.unavailable)
          .toList(),
    );
  }

  /// [accounts] is the list after [id] stopped being usable: the active
  /// account stays unless it is [id], then the next usable one takes over.
  AccountsState _withoutActive(
    Active state,
    String id,
    List<Account> accounts,
  ) {
    if (id != state.activeId) {
      return Active(accounts: accounts, activeId: state.activeId);
    }
    final nextId = _nextUsable(state.accounts, id);
    if (nextId == null) return _support.noSurvivor(accounts);
    return Active(accounts: accounts, activeId: nextId);
  }

  /// The account that becomes active when [id] stops being it: the next one
  /// that is logged in, by [AccountPolicy.nextActiveAfterRemoving].
  String? _nextUsable(List<Account> accounts, String id) =>
      _policy.nextActiveAfterRemoving(
        ids: [
          for (final a in accounts)
            if (a.isLoggedIn || a.id == id) a.id,
        ],
        removedId: id,
      );
}
