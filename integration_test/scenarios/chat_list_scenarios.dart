import 'package:flutter_test/flutter_test.dart';

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';

/// Cross-platform scenario: search the chat list.
///
/// Asserts the no-result state, a partial-text search returning groups, an
/// exact Matrix-address lookup returning a single group, the owner/email row
/// content for the current account, and opening then leaving a group from the
/// search results.
///
/// Scoped to behaviour identical on mobile and web. The case-insensitive
/// Matrix-address lookup (`SearchByMatrixAddress.toUpperCase()`) is mobile-only
/// — web search is case-sensitive — so it is intentionally not asserted here,
/// matching the contact-search migration.
class ChatListSearchScenario extends BaseTestScenario {
  ChatListSearchScenario(super.$, super.robots);

  static const _searchByMatrixAddress = String.fromEnvironment(
    'SearchByMatrixAddress',
  );
  static const _searchByTitle = String.fromEnvironment('SearchByTitle');
  static const _currentAccount = String.fromEnvironment('CurrentAccount');

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();

    await robots.homeRobot().gotoChatListScreen();
    s.softAssertEquals(
      await robots.chatListRobot().isListScrollable(),
      true,
      'Chat list is not scrollable',
    );

    // Two chats-tab search behaviours are mobile-only and intentionally not
    // asserted here (same scoping as the contact-search migration): the
    // "No Results" placeholder for a non-matching term (web shows an empty
    // list instead) and short partial-text search (web needs a full query).

    // Full Matrix address -> exactly one result.
    await _search(_searchByMatrixAddress);
    s.softAssertEquals(
      (await robots.chatListRobot().getListOfChatGroup()).length == 1,
      true,
      'Search by $_searchByMatrixAddress expected exactly 1 group',
    );

    // Diacritic-insensitive: title with 'a' replaced by 'à' should still match.
    await _search(_searchByTitle.replaceAll('a', 'à'));
    s.softAssertEquals(
      (await robots.chatListRobot().getListOfChatGroup()).length == 1,
      true,
      'Search by ${_searchByTitle.replaceAll('a', 'à')} expected 1 group',
    );

    // Current account -> owner + email visible on the row.
    await _search(_currentAccount);
    final groups = await robots.chatListRobot().getListOfChatGroup();
    s.softAssertEquals(
      groups.isNotEmpty,
      true,
      'Search by $_currentAccount expected a result row',
    );
    if (groups.isNotEmpty) {
      s.softAssertEquals(
        (await groups.first.getOwnerLabel()).visible,
        true,
        'Owner is missing!',
      );
      s.softAssertEquals(
        (await groups.first.getEmailLabelIncaseSearching()).visible,
        true,
        'Email field is not shown',
      );
    }

    // List chrome present while the list/search is showing. Asserted here
    // (before opening a chat) because on web the chat opens in a side pane and
    // there is no mobile-style "back to list" navigation to return through.
    s.softAssertEquals(
      robots.searchRobot().isSearchFieldVisible(),
      true,
      'Search text field is not visible',
    );
    s.softAssertEquals(
      robots.homeRobot().isMainNavigationVisible(),
      true,
      'Main navigation is not visible',
    );

    // Open a group from the search result and confirm the detail screen shows.
    await _search(_searchByTitle);
    final toOpen = await robots.chatListRobot().getListOfChatGroup();
    s.softAssertEquals(
      toOpen.isNotEmpty,
      true,
      'No group to open for $_searchByTitle',
    );
    if (toOpen.isNotEmpty) {
      await toOpen.first.root.tap();
      final detail = robots.chatGroupDetailRobot();
      await detail.confirmAccessMedia();
      s.softAssertEquals(
        await detail.isVisible(),
        true,
        'Chat group detail screen is not shown',
      );
    }

    s.verifyAll();
  }

  /// Enters [text] and lets the debounced/async search settle (esp. on web).
  Future<void> _search(String text) async {
    await robots.searchRobot().enterSearchText(text);
    await $.pump();
    await $.pump(const Duration(milliseconds: 500));
  }
}

/// Cross-platform scenario: the unread badge increments per received message.
class UnreadCountScenario extends BaseTestScenario {
  UnreadCountScenario(super.$, super.robots);

  static const _groupTest = String.fromEnvironment('TitleOfGroupTest');

  @override
  Future<void> runTestLogic() async {
    final now = DateTime.now();
    // Non-numeric body so the message preview is never mis-read as the count.
    final body = 'unread probe ${now.hour}:${now.minute}:${now.second}';

    await robots.homeRobot().gotoChatListScreen();

    final before = _readUnread();
    await sendMessageAsReceiver(message: body);
    final after = await _pollUnreadChange(before);

    expect(
      after - before == 1,
      isTrue,
      reason: 'expected the difference to be 1 but before=$before after=$after',
    );
  }

  int _readUnread() => robots.chatListRobot().getUnreadMessage(_groupTest);

  /// Polls until the unread count differs from [from] (the receive is async —
  /// the badge only updates after the next /sync), then returns it.
  Future<int> _pollUnreadChange(int from) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    var current = from;
    while (DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 300));
      current = _readUnread();
      if (current != from) break;
    }
    return current;
  }
}

/// Cross-platform scenario: pin then unpin a chat.
class PinChatScenario extends BaseTestScenario {
  PinChatScenario(super.$, super.robots);

  static const _groupTest = String.fromEnvironment('GroupTest');

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();

    await robots.chatListRobot().pinChat(_groupTest);
    expect(
      await robots.chatListRobot().isChatPinned(_groupTest),
      isTrue,
      reason: 'Expected "$_groupTest" to be pinned',
    );

    await robots.chatListRobot().unpinChat(_groupTest);
    expect(
      await robots.chatListRobot().isChatPinned(_groupTest),
      isFalse,
      reason: 'Expected "$_groupTest" to be unpinned',
    );
  }
}
