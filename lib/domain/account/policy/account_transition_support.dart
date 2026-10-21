import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';

/// Helpers shared by the transition groups of [AccountTransitions].
abstract final class AccountTransitionSupport {
  static bool has(List<Account> accounts, String id) =>
      accounts.any((a) => a.id == id);

  static InvalidAccountTransitionException invalid(
    String transition,
    AccountsState state,
  ) => InvalidAccountTransitionException(
    transition: transition,
    stateName: state.runtimeType.toString(),
  );

  /// Nobody is logged in: the first account that is not waiting for its
  /// removal is the placeholder of the next login, the others stay listed.
  static NoAccount noSurvivor(List<Account> accounts) => NoAccount(
    candidateId: accounts
        .where((a) => a.status != AccountStatus.unavailable)
        .firstOrNull
        ?.id,
    accounts: accounts
        .where((a) => a.status == AccountStatus.unavailable)
        .toList(),
  );
}
