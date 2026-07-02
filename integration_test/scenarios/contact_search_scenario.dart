import 'package:fluffychat/pages/contacts_tab/contacts_tab_body_view.dart';

import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/twake_list_item_robot.dart';

/// Cross-platform scenario for searching contacts.
///
/// Asserts the no-result state, an exact Matrix-address lookup (with row
/// content: a searched contact hides the "Owner" label and shows the email,
/// the current account shows the "Owner" label), and that the contacts screen
/// stays correctly displayed.
///
/// Scoped to behaviour that is identical on mobile and web. Two contact-search
/// behaviours are mobile-only and intentionally not asserted here: short
/// partial-text directory search (web needs a longer query) and
/// case-insensitive Matrix-id lookup (web is case-sensitive).
///
/// Drives the UI exclusively through the abstract robots exposed by the
/// `RobotFactory`, so the same scenario runs on mobile and web.
class ContactSearchScenario extends BaseTestScenario {
  ContactSearchScenario(super.$, super.robots);

  static const _searchByMatrixAddress = String.fromEnvironment(
    'SearchByMatrixAddress',
  );
  static const _searchByTitle = String.fromEnvironment('SearchByTitle');
  static const _currentAccount = String.fromEnvironment('CurrentAccount');

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();

    await robots.homeRobot().gotoContactListScreen();
    s.softAssertEquals(
      await robots.contactListRobot().isListScrollable(),
      true,
      'Contact list is not scrollable',
    );

    await _searchAndWait('noexist', expectResults: false);
    s.softAssertEquals(
      robots.searchRobot().isNoResultVisible(),
      true,
      'label "No Results" is not shown',
    );

    final byAddress = await _expectSingleResult(s, _searchByMatrixAddress);
    await _verifyOwnerAndEmail(s, byAddress, ownerVisible: false);

    final byAccount = await _expectSingleResult(s, _currentAccount);
    await _verifyOwnerAndEmail(s, byAccount, ownerVisible: true);

    // Diacritic-insensitive: title with 'a' replaced by 'à' should still match.
    final diacriticQuery = _searchByTitle.replaceAll('a', 'à');
    s.softAssertEquals(
      diacriticQuery != _searchByTitle,
      true,
      'SearchByTitle must contain "a" to verify diacritic-insensitive search',
    );
    final byTitleDiacritic = await _searchAndWait(
      diacriticQuery,
      expectResults: true,
    );
    s.softAssertEquals(
      byTitleDiacritic.length == 1,
      true,
      'Search by $diacriticQuery expected 1 contact',
    );
    await _verifyOwnerAndEmail(s, byTitleDiacritic, ownerVisible: false);

    await _verifyContactListScreen(s);

    s.verifyAll();
  }

  /// Enters [text] in the search field, then polls until the result state is
  /// stable: at least one contact (when [expectResults]) or the "No Results"
  /// placeholder otherwise. Search is debounced and async, so a single pump
  /// is not enough — especially on web.
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

  Future<List<TwakeListItemRobot>> _expectSingleResult(
    SoftAssertHelper s,
    String query,
  ) async {
    final contacts = await _searchAndWait(query, expectResults: true);
    s.softAssertEquals(
      contacts.length == 1,
      true,
      'Search by $query expected exactly 1 result, found ${contacts.length}',
    );
    return contacts;
  }

  Future<void> _verifyOwnerAndEmail(
    SoftAssertHelper s,
    List<TwakeListItemRobot> contacts, {
    required bool ownerVisible,
  }) async {
    if (contacts.isEmpty) {
      s.softAssertEquals(false, true, 'no contact row to verify owner/email');
      return;
    }
    final first = contacts.first;
    s.softAssertEquals(
      (await first.getOwnerLabel()).visible,
      ownerVisible,
      ownerVisible ? 'Owner is missing!' : 'Owner should be hidden',
    );
    s.softAssertEquals(
      (await first.getEmailLabelIncaseSearching()).visible,
      true,
      'Email field is not shown',
    );
  }

  Future<void> _verifyContactListScreen(SoftAssertHelper s) async {
    s.softAssertEquals(
      robots.searchRobot().isSearchFieldVisible(),
      true,
      'Search text field is not visible',
    );
    s.softAssertEquals(
      $(ContactsTabBodyView).visible,
      true,
      'Contacts tab is not visible',
    );
    s.softAssertEquals(
      robots.homeRobot().isMainNavigationVisible(),
      true,
      'Main navigation is not visible',
    );
  }
}
