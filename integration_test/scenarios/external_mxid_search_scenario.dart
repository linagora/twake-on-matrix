import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/twake_list_item_robot.dart';

/// Cross-platform scenario for searching a contact by exact Matrix ID.
///
/// Asserts the no-result state for a non-existent mxid and a successful
/// profile lookup for the current account's mxid. Scoped to behaviour that is
/// identical on mobile and web (exact Matrix-address lookup).
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`, so the same scenario runs on mobile and web.
class ExternalMxidSearchScenario extends BaseTestScenario {
  ExternalMxidSearchScenario(super.$, super.robots);

  static const _currentAccount = String.fromEnvironment('CurrentAccount');
  static const _nonExistentMxid =
      '@nonexistent_test_user_xyz_000:fake.server.invalid';

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();

    await robots.homeRobot().gotoContactListScreen();

    // Case 1: a non-existent mxid yields "No Results" and no contact tile.
    await _searchAndWait(_nonExistentMxid, expectResults: false);
    s.softAssertEquals(
      robots.searchRobot().isNoResultVisible(),
      true,
      'Expected "No Results" for a non-existent mxid, but it was not shown',
    );
    s.softAssertEquals(
      (await robots.contactListRobot().getListOfContact()).isEmpty,
      true,
      'Expected no contact tile for a non-existent mxid, but one was found',
    );

    // Case 2: the current account's mxid resolves to a profile tile.
    await robots.searchRobot().deleteSearchPhrase();
    final contacts = await _searchAndWait(_currentAccount, expectResults: true);
    s.softAssertEquals(
      robots.searchRobot().isNoResultVisible(),
      false,
      'Expected a profile for a valid mxid, but got "No Results"',
    );
    s.softAssertEquals(
      contacts.isNotEmpty,
      true,
      'Expected a contact tile to be rendered for a valid mxid',
    );

    s.verifyAll();
  }

  /// Enters [text] in the search field, then polls until the result state is
  /// stable: at least one contact (when [expectResults]) or the "No Results"
  /// placeholder otherwise. The profile lookup is async, so a single pump is
  /// not enough — especially on web.
  Future<List<TwakeListItemRobot>> _searchAndWait(
    String text, {
    required bool expectResults,
  }) async {
    await robots.searchRobot().enterSearchText(text);
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 200));
      final contacts = await robots.contactListRobot().getListOfContact();
      if (expectResults) {
        if (contacts.isNotEmpty) return contacts;
      } else if (robots.searchRobot().isNoResultVisible()) {
        return contacts;
      }
    }
    return robots.contactListRobot().getListOfContact();
  }
}
