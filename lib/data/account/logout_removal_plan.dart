import 'package:twake_chat/data/account/logout_removals.dart';
import 'package:twake_chat/domain/account/entities/account_id.dart';
import 'package:twake_chat/domain/account/exceptions/account_exception.dart';
import 'package:twake_chat/providers/accounts_provider.dart';

/// The steps that take a logged-out account away, wired to the account state.
/// Built once per logout and kept by [LogoutRemovals], so a retry runs the same
/// plan: whether the account was the active one is decided on the first try,
/// before anything can fail, and never again.
class LogoutRemovalPlan {
  LogoutRemovalPlan({
    required this.id,
    required Accounts accounts,
    required bool Function() isActive,
    required Future<void> Function() cancelSubscriptions,
    required Future<void> Function() activateReplacement,
    Future<void> Function()? announce,
  }) : _accounts = accounts,
       _isActive = isActive,
       _cancelSubscriptions = cancelSubscriptions,
       _activateReplacement = activateReplacement,
       _announce = announce;

  final String id;
  final Accounts _accounts;
  final bool Function() _isActive;
  final Future<void> Function() _cancelSubscriptions;
  final Future<void> Function() _activateReplacement;

  /// Null when the user already knows (a removal retried after a restart).
  final Future<void> Function()? _announce;

  bool? _wasActive;
  bool _announced = false;

  late final RemovalSteps steps = RemovalSteps(
    remove: _remove,
    hold: _hold,
    persist: () => _accounts.recordPendingRemoval(AccountId(id)),
    settle: _settle,
  );

  Future<void> _remove() async {
    // A removal is rejected during a switch: wait for it to end.
    await _accounts.whenSwitchSettled();
    _wasActive ??= _isActive();
    await _cancelSubscriptions();
    await _writeAfterSwitch(() => _accounts.removeAccount(AccountId(id)));
  }

  Future<void> _hold() async {
    await _accounts.whenSwitchSettled();
    await _writeAfterSwitch(() => _accounts.holdRemoval(AccountId(id)));
  }

  /// A switch can start after the wait above, while a step runs: the write is
  /// then refused before it changes anything. That is expected, not a failure
  /// to report, so wait for the switch and write once more. A second refusal
  /// reaches the removals, which retry it.
  Future<void> _writeAfterSwitch(Future<void> Function() write) async {
    try {
      await write();
    } on SwitchInProgressException {
      await _accounts.whenSwitchSettled();
      await write();
    }
  }

  /// The account list changed, by a hold or by the removal: once, however many
  /// tries it takes, the announcement and the replacement account's effects.
  /// The announcement counts as done only when it worked, so a failure is
  /// retried.
  Future<void> _settle() async {
    final announce = _announce;
    if (announce != null && !_announced) {
      await announce();
      _announced = true;
    }
    if (_wasActive ?? false) await _activateReplacement();
  }
}
