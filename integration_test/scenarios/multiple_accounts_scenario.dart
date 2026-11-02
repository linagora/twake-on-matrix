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

  @override
  Future<void> runTestLogic() async {
    if (_serverUrl.isEmpty || _receiver.isEmpty || _receiverPass.isEmpty) {
      throw StateError(
        'Missing SERVER_URL, Receiver or ReceiverPass dart-define',
      );
    }
    final s = SoftAssertHelper();
    final robot = MultipleAccountsRobot($);
    final accountA = robot.activeUserId()!;
    String? accountB;

    try {
      accountB = await robot.addAccount(
        serverUrl: _serverUrl,
        username: _receiver,
        password: _receiverPass,
      );
      s.softAssertEquals(
        accountB != accountA,
        true,
        'the added account is the same as the first one',
      );

      final listed = await robot.listedAccounts();
      s.softAssertEquals(
        listed.contains(accountA) && listed.contains(accountB),
        true,
        'account picker does not list both accounts: $listed',
      );

      await robot.switchTo(accountA);
      s.softAssertEquals(robot.activeUserId(), accountA, 'A is not active');

      await robot.switchTo(accountB);
      s.softAssertEquals(robot.activeUserId(), accountB, 'B is not active');

      await robot.logoutActiveAccount();
      await robot.waitForActiveAccount(accountA);
      s.softAssertEquals(robot.loggedInUserIds(), [
        accountA,
      ], 'A is not the only remaining account after logging B out');
    } finally {
      // Leave only account A logged in, even if a step above failed.
      if (accountB != null && robot.loggedInUserIds().contains(accountB)) {
        if (robot.activeUserId() != accountB) await robot.switchTo(accountB);
        await robot.logoutActiveAccount();
        await robot.waitForActiveAccount(accountA);
      }
    }

    s.verifyAll();
  }
}
