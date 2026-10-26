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
        accounts: List.unmodifiable(accounts),
        activeId: _initialActiveId(loggedIn, persistedUserId),
      );
    }
    return _support.noSurvivor(accounts);
  }

  String _initialActiveId(List<Account> loggedIn, String? persistedUserId) {
    final persisted = loggedIn
        .where((a) => persistedUserId != null && a.userId == persistedUserId)
        .map((a) => a.id)
        .firstOrNull;
    return _policy.selectInitialActive(
      loggedInIds: loggedIn.map((a) => a.id).toList(),
      persistedId: persisted,
    );
  }
}
