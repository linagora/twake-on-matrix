import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/setting/multiple_accounts_robot.dart';

/// Mobile-only: with account A logged in, add account B through
/// "Add another account", check the picker lists both, switch to B and back
/// to A, then log B out and check A is still active.
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
    String? accountB;

    try {
      accountB = await _addSecondAccount(accountA);
      await _verifyBothListed(accountA, accountB);
      await _switchAndVerify(accountA, 'A');
      await _switchAndVerify(accountB, 'B');
      await _logoutSecondAndVerify(accountA);
    } finally {
      await _cleanup(accountA, accountB);
    }

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
    _s.softAssertEquals(
      accountB != accountA,
      true,
      'the added account is the same as the first one',
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
  }

  Future<void> _logoutSecondAndVerify(String accountA) async {
    await _robot.logoutActiveAccount();
    await _robot.waitForActiveAccount(accountA);
    _s.softAssertEquals(_robot.loggedInUserIds(), [
      accountA,
    ], 'A is not the only remaining account after logging B out');
  }

  /// Leaves only account A logged in, even if a step above failed.
  Future<void> _cleanup(String accountA, String? accountB) async {
    if (accountB == null) return;
    if (!_robot.loggedInUserIds().contains(accountB)) return;
    if (_robot.activeUserId() != accountB) await _robot.switchTo(accountB);
    await _robot.logoutActiveAccount();
    await _robot.waitForActiveAccount(accountA);
  }
}
