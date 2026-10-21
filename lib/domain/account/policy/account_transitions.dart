import 'package:twake_chat/domain/account/entities/account.dart';
import 'package:twake_chat/domain/account/entities/accounts_state.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/domain/account/policy/account_policy.dart';

/// Pure transitions between [AccountsState]s. Each returns the next state or
/// throws; the input state is never changed.
abstract final class AccountTransitions {
  static AccountsState initialize(
    AccountsState state,
    List<Account> accounts, {
    String? persistedUserId,
  }) {
    if (state is! Booting) throw _invalid('initialize', state);
    final loggedIn = accounts.where((a) => a.isLoggedIn).toList();
    if (loggedIn.isNotEmpty) {
      final persisted = loggedIn
          .where((a) => persistedUserId != null && a.userId == persistedUserId)
          .map((a) => a.id)
          .firstOrNull;
      final activeId = AccountPolicy.selectInitialActive(
        loggedInIds: loggedIn.map((a) => a.id).toList(),
        persistedId: persisted,
      );
      return Active(accounts: accounts, activeId: activeId!);
    }
    final failed = accounts
        .where((a) => a.status == AccountStatus.initFailed)
        .toList();
    if (failed.isEmpty) return _noSurvivor(accounts);
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
    return _noSurvivor(others.toList());
  }

  /// Nobody is logged in: the first account that is not waiting for its
  /// removal is the placeholder of the next login, the others stay listed.
  static NoAccount _noSurvivor(List<Account> accounts) => NoAccount(
    candidateId: accounts
        .where((a) => a.status != AccountStatus.unavailable)
        .firstOrNull
        ?.id,
    accounts: accounts
        .where((a) => a.status == AccountStatus.unavailable)
        .toList(),
  );

  /// Registers a logged-in [account]. After the last logout only that same
  /// account can come back. From [Active] the active account does
  /// not change; follow with [beginSwitch] to make it active. From [NoAccount]
  /// the accounts that wait for their removal stay listed.
  static AccountsState add(AccountsState state, Account account) {
    if (!account.isLoggedIn) throw _invalid('add', state);
    return switch (state) {
      NoAccount(:final accounts) => Active(
        accounts: [...accounts, account],
        activeId: account.id,
      ),
      Active(:final accounts, :final activeId)
          when !_has(accounts, account.id) =>
        Active(accounts: [...accounts, account], activeId: activeId),
      LastLoggedOut(account: final last) when last.id == account.id => Active(
        accounts: [account],
        activeId: account.id,
      ),
      _ => throw _invalid('add', state),
    };
  }

  /// Starts a switch to [toId]. [seq] numbers the switch; its settlement hands
  /// it back to [completeSwitch] or [failSwitch].
  static AccountsState beginSwitch(
    AccountsState state,
    String toId, {
    int seq = 0,
  }) {
    final target = state.accounts.where((a) => a.id == toId).firstOrNull;
    if (target == null) throw UnknownAccountException(toId);
    if (!target.isLoggedIn) throw _invalid('beginSwitch', state);
    return switch (state) {
      Active(:final accounts, :final activeId) =>
        toId == activeId
            ? state
            : Switching(accounts: accounts, from: activeId, to: toId, seq: seq),
      Switching(:final accounts, :final from) =>
        toId == from
            ? Active(accounts: accounts, activeId: from)
            : Switching(accounts: accounts, from: from, to: toId, seq: seq),
      _ => throw _invalid('beginSwitch', state),
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
    if (state is! Switching) throw _invalid(transition, state);
    if (state.seq != expectedSeq) throw SwitchSupersededException(state.to);
    return Active(accounts: state.accounts, activeId: landOn(state));
  }

  /// Removes [id] while other accounts remain. Removing a non-active account
  /// never changes the active one; removing the active one picks the next by
  /// [AccountPolicy.nextActiveAfterRemoving], and with no logged-in account
  /// left nobody is logged in ([NoAccount], which keeps the accounts that wait
  /// for their removal). The only account goes through [logoutLast]. An
  /// account that waits for its removal is removed from [NoAccount] too.
  static AccountsState remove(AccountsState state, String id) {
    if (!_has(state.accounts, id)) throw UnknownAccountException(id);
    if (state is NoAccount) {
      return NoAccount(
        candidateId: state.candidateId,
        accounts: state.accounts.where((a) => a.id != id).toList(),
      );
    }
    if (state is! Active || state.accounts.length < 2) {
      throw _invalid('remove', state);
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
    if (!_has(state.accounts, id)) throw UnknownAccountException(id);
    if (state is NoAccount) return state;
    if (state is! Active) throw _invalid('markUnavailable', state);
    final accounts = [
      for (final a in state.accounts)
        a.id == id ? a.withStatus(AccountStatus.unavailable) : a,
    ];
    return _withoutActive(state, id, accounts);
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
    if (nextId == null) return _noSurvivor(accounts);
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

  /// The last logged-in account logs out but stays, marked logged out, so the
  /// next login can reuse it. The accounts that wait for their removal stay
  /// listed beside it ([NoAccount]); with none, it is [LastLoggedOut].
  static AccountsState logoutLast(AccountsState state) {
    if (state is! Active) throw _invalid('logoutLast', state);
    final others = state.accounts.where((a) => a.id != state.activeId);
    final loggedOut = state.accounts
        .firstWhere((a) => a.id == state.activeId)
        .withStatus(AccountStatus.loggedOut);
    if (others.isEmpty) return LastLoggedOut(account: loggedOut);
    if (others.any((a) => a.status != AccountStatus.unavailable)) {
      throw _invalid('logoutLast', state);
    }
    return NoAccount(candidateId: loggedOut.id, accounts: others.toList());
  }

  static bool _has(List<Account> accounts, String id) =>
      accounts.any((a) => a.id == id);

  static InvalidAccountTransitionException _invalid(
    String transition,
    AccountsState state,
  ) => InvalidAccountTransitionException(
    transition: transition,
    stateName: state.runtimeType.toString(),
  );
}
