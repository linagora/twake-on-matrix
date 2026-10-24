import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';

/// Helpers shared by the transition groups of [AccountTransitions].
class AccountTransitionSupport {
  const AccountTransitionSupport();

  bool has(List<Account> accounts, String id) =>
      accounts.any((a) => a.id == id);

  InvalidAccountTransitionException invalid(
    String transition,
    AccountsState state,
  ) => InvalidAccountTransitionException(
    transition: transition,
    stateName: switch (state) {
      Booting() => 'Booting',
      NoAccount() => 'NoAccount',
      Active() => 'Active',
      Switching() => 'Switching',
      LastLoggedOut() => 'LastLoggedOut',
    },
  );

  /// Nobody is logged in: the first logged-out account is the placeholder of
  /// the next login, the accounts that wait for their removal stay listed.
  NoAccount noSurvivor(List<Account> accounts) => NoAccount(
    candidateId: accounts
        .where((a) => a.status == AccountStatus.loggedOut)
        .firstOrNull
        ?.id,
    accounts: accounts
        .where((a) => a.status == AccountStatus.unavailable)
        .toList(),
  );
}
