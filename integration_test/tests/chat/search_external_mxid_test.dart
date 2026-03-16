import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import '../../base/core_robot.dart';
import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/contact_list_robot.dart';
import '../../robots/home_robot.dart';
import '../../robots/search_robot.dart';
import '../../scenarios/contact_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Search external contact by Matrix ID validates profile',
    test: ($) async {
      final s = SoftAssertHelper();

      const currentAccount = String.fromEnvironment('CurrentAccount');

      // Navigate to Contacts tab
      await HomeRobot($).gotoContactListScreen();

      // --- Case 1: search a non-existent mxid ---
      const nonExistentMxid =
          '@nonexistent_test_user_xyz_000:fake.server.invalid';
      await ContactScenario($).enterSearchText(nonExistentMxid);

      // Wait for the profile lookup to finish (loading → result)
      await CoreRobot($).waitForEitherVisible(
        $: $,
        first: $(NoContactsFound),
        second: $(ExpansionContactListTile),
        timeout: const Duration(seconds: 30),
      );
      await $.pumpAndTrySettle();

      // "No Results" should be shown for a non-existent mxid
      s.softAssertEquals(
        $(NoContactsFound).exists || (SearchRobot($).getNoResultIcon()).exists,
        true,
        'Expected "No Results" to be shown for non-existent mxid, but it was not',
      );

      // No contact tile should be displayed
      s.softAssertEquals(
        $(ExpansionContactListTile).exists,
        false,
        'Expected no contact tile for non-existent mxid, but one was found',
      );

      // --- Case 2: search a valid mxid (current account) ---
      await SearchRobot($).deleteSearchPhrase();
      await ContactScenario($).enterSearchText(currentAccount);

      // Wait for the profile lookup to finish
      await CoreRobot($).waitForEitherVisible(
        $: $,
        first: $(NoContactsFound),
        second: $(ExpansionContactListTile),
        timeout: const Duration(seconds: 30),
      );
      await $.pumpAndTrySettle();

      // "No Results" should NOT be shown — a contact tile should be displayed
      s.softAssertEquals(
        $(NoContactsFound).exists,
        false,
        'Expected profile info to be shown for valid mxid, but got "No Results"',
      );

      // A contact list item should be visible (external contact tile)
      final contacts = await ContactListRobot($).getListOfContact();
      s.softAssertEquals(
        contacts.isNotEmpty || $(ExpansionContactListTile).exists,
        true,
        'Expected a contact tile to be rendered for valid mxid',
      );

      s.verifyAll();
    },
  );
}
