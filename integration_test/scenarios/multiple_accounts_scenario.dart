import 'package:flutter/foundation.dart';
import 'package:twake_chat/presentation/enum/settings/settings_profile_enum.dart';

import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/setting/multiple_accounts_robot.dart';

/// Mobile-only: with account A logged in, add account B, check the picker
/// lists both, switch to A, then to B, then back to A (B is already active after
/// the add step, so the first switch is the one that changes the account), then
/// log A out (the first account of the list) and check B became active, then log
/// B out and check the app is back on the welcome screen.
///
/// The add step logs B in through the same path as the initial test login: it
/// does not go through the sign-in of the welcome screen, so the guard against
/// a second account on the same homeserver is not covered. Switching and both
/// logouts are.
///
/// Guards the legacy multiple-account behaviour before the account module
/// migration (ADR 0037 §7). Account B is the existing `Receiver` /
/// `ReceiverPass` test user; no credential is hardcoded.
class MultipleAccountsScenario extends BaseTestScenario {
  MultipleAccountsScenario(super.$, super.robots);

  static const _serverUrl = String.fromEnvironment('SERVER_URL');
  static const _receiver = String.fromEnvironment('Receiver');
  static const _receiverPass = String.fromEnvironment('ReceiverPass');

  final _s = SoftAssertHelper();
  late final _robot = MultipleAccountsRobot($);

  @override
  Future<void> runTestLogic() async {
    _checkDefines();
    final accountA = _robot.activeUserId()!;

    final accountB = await _addSecondAccount(accountA);
    await _verifyBothListed(accountA, accountB);
    await _switchAndVerify(accountA, 'A');
    await _switchAndVerify(accountB, 'B');
    await _switchAndVerify(accountA, 'A');
    await _logoutFirstAndVerify(accountB);
    await _logoutLastAndVerify();

    _s.verifyAll();
  }

  void _checkDefines() {
    final missing = [
      _serverUrl,
      _receiver,
      _receiverPass,
    ].any((value) => value.isEmpty);
    if (!missing) return;
    throw StateError(
      'Missing SERVER_URL, Receiver or ReceiverPass dart-define',
    );
  }

  Future<String> _addSecondAccount(String accountA) async {
    final accountB = await _robot.addAccount(
      serverUrl: _serverUrl,
      username: _receiver,
      password: _receiverPass,
    );
    final expectedPrefix = _receiver.startsWith('@')
        ? _receiver
        : '@$_receiver:';
    _s.softAssertEquals(
      accountB != accountA && accountB.startsWith(expectedPrefix),
      true,
      'the added account is "$accountB", not the "$_receiver" user',
    );
    return accountB;
  }

  Future<void> _verifyBothListed(String accountA, String accountB) async {
    final listed = await _robot.listedAccounts();
    _s.softAssertEquals(
      [accountA, accountB].every(listed.contains),
      true,
      'account picker does not list both accounts: $listed',
    );
  }

  Future<void> _switchAndVerify(String account, String label) async {
    await _robot.switchTo(account);
    _s.softAssertEquals(_robot.activeUserId(), account, '$label is not active');
    // The provider is only one side of the switch: the profile reads the
    // account from `MatrixState`.
    final profile = await _robot.openProfile();
    _s.softAssertEquals(
      await profile.waitForValueOf(SettingsProfileEnum.matrixId),
      account,
      'Profile does not show $label after the switch',
    );
    await profile.backToSettings();
  }

  /// A is the active account and the first of the list: logging it out must
  /// leave B active and alone.
  Future<void> _logoutFirstAndVerify(String accountB) async {
    // The case of #3540 needs the active account to be the first of the list;
    // the scenario stops covering it if the order changes.
    _s.softAssertEquals(
      _robot.loggedInUserIds().first,
      _robot.activeUserId(),
      'the active account is not the first of the list',
    );
    await _robot.logoutActiveAccount();
    await _robot.waitForActiveAccount(accountB);
    final remaining = _robot.loggedInUserIds();
    _s.softAssertEquals(
      listEquals(remaining, [accountB]),
      true,
      'B is not the only remaining account after logging A out: $remaining',
    );
  }

  Future<void> _logoutLastAndVerify() async {
    await _robot.logoutActiveAccount();
    await _robot.waitForWelcome();
    _s.softAssertEquals(
      _robot.loggedInUserIds().isEmpty,
      true,
      'an account is still logged in after the last logout',
    );
  }
}
