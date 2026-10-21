import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/policy/account_policy.dart';
import 'package:twake_chat/domain/account/policy/account_transition_support.dart';

/// The transition out of [Booting].
class AccountInitTransitions {
  const AccountInitTransitions(this._policy, this._support);

  final AccountPolicy _policy;
  final AccountTransitionSupport _support;

  AccountsState initialize(
    AccountsState state,
    List<Account> accounts, {
    String? persistedUserId,
  }) {
    if (state is! Booting) {
      throw _support.invalid('initialize', state);
    }
    final loggedIn = accounts.where((a) => a.isLoggedIn).toList();
    if (loggedIn.isNotEmpty) {
      return Active(
        accounts: accounts,
        activeId: _initialActiveId(loggedIn, persistedUserId),
      );
    }
    return _withoutLoggedIn(accounts);
  }

  String _initialActiveId(List<Account> loggedIn, String? persistedUserId) {
    final persisted = loggedIn
        .where((a) => persistedUserId != null && a.userId == persistedUserId)
        .map((a) => a.id)
        .firstOrNull;
    return _policy.selectInitialActive(
      loggedInIds: loggedIn.map((a) => a.id).toList(),
      persistedId: persisted,
    )!;
  }

  AccountsState _withoutLoggedIn(List<Account> accounts) {
    final failed = accounts
        .where((a) => a.status == AccountStatus.initFailed)
        .toList();
    if (failed.isEmpty) return _support.noSurvivor(accounts);
    final others = accounts.where((a) => a.status != AccountStatus.initFailed);
    if (others.every((a) => a.status == AccountStatus.unavailable)) {
      return AccountInitFailed(
        id: failed.first.id,
        error: failed.first.initError,
        accounts: others.toList(),
      );
    }
    // A logged-out placeholder exists: the next login can use it, so the
    // failed accounts do not block the app. They stay in the store.
    return _support.noSurvivor(others.toList());
  }
}
