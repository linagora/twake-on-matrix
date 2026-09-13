import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';
import '../help/soft_assertion_helper.dart';

/// Resolves the group the chat-list scenarios operate on.
///
/// Web runs against the isolated Synapse fixture provisioned by the workflow
/// (`TitleOfGroupTest`, `GroupID`). Mobile runs against a shared staging
/// account with no such staged room, so it uses the in-app room fixture and its
/// room id for API-sent messages.
Future<(String, String?)> _resolveGroupFixture(
  BaseTestScenario scenario,
) async {
  if (kIsWeb) {
    return (const String.fromEnvironment('TitleOfGroupTest'), null);
  }
  final fixture = await prepareMobileGroupFixture(scenario);
  return (fixture.title, fixture.roomId);
}

/// Cross-platform scenario: search the chat list.
///
/// Asserts a partial-text search returning groups, an exact Matrix-address
/// lookup returning the fixture group, the diacritic-insensitive title match,
/// the owner/email row content for the current account, and opening a group
/// from the search results.
///
/// Scoped to behaviour identical on mobile and web. The case-insensitive
/// Matrix-address lookup (`SearchByMatrixAddress.toUpperCase()`) is mobile-only
/// — web search is case-sensitive — so it is intentionally not asserted here,
/// matching the contact-search migration.
class ChatListSearchScenario extends BaseTestScenario {
  ChatListSearchScenario(super.$, super.robots);

  static const _webSearchByMatrixAddress = String.fromEnvironment(
    'SearchByMatrixAddress',
  );
  static const _webSearchByTitle = String.fromEnvironment('SearchByTitle');
  static const _currentAccount = String.fromEnvironment('CurrentAccount');

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();

    await robots.homeRobot().gotoChatListScreen();
    // Asserted with the list at rest: on mobile an active search field raises
    // the keyboard over the bottom navigation, so the nav is hit-testable only
    // before the first search.
    s.softAssertEquals(
      robots.homeRobot().isMainNavigationVisible(),
      true,
      'Main navigation is not visible',
    );
    s.softAssertEquals(
      await robots.chatListRobot().isListScrollable(),
      true,
      'Chat list is not scrollable',
    );

    // Resolve the platform fixture. Mobile uses an in-app room whose title
    // contains an uppercase "U" so the diacritic probe stays meaningful.
    final String searchByTitle;
    final String searchByMatrixAddress;
    if (!kIsWeb) {
      final fixture = await prepareMobileRoomFixture(
        this,
        mobileChatListFixtureTitle,
      );
      searchByTitle = fixture.title;
      searchByMatrixAddress = fixture.memberMatrixId;
    } else {
      searchByTitle = _webSearchByTitle;
      searchByMatrixAddress = _webSearchByMatrixAddress;
    }

    // Two chats-tab search behaviours are mobile-only and intentionally not
    // asserted here (same scoping as the contact-search migration): the
    // "No Results" placeholder for a non-matching term (web shows an empty
    // list instead) and short partial-text search (web needs a full query).

    // Full Matrix address -> the fixture group. On web the staged account is a
    // member of exactly one room; on the shared mobile account the receiver can
    // already belong to other rooms, so only presence is asserted there.
    await _search(searchByMatrixAddress);
    final addressMatches =
        (await robots.chatListRobot().getListOfChatGroup()).length;
    s.softAssertEquals(
      kIsWeb ? addressMatches == 1 : addressMatches >= 1,
      true,
      'Search by $searchByMatrixAddress expected '
      '${kIsWeb ? 'exactly 1' : 'at least 1'} group, got $addressMatches',
    );

    // Diacritic-insensitive: title with 'U' replaced by 'Ù' should still match.
    final diacriticQuery = searchByTitle.replaceAll('U', 'Ù');
    s.softAssertEquals(
      diacriticQuery != searchByTitle,
      true,
      'SearchByTitle must contain "U" to verify diacritic-insensitive search',
    );
    await _search(diacriticQuery);
    s.softAssertEquals(
      (await robots.chatListRobot().getListOfChatGroup()).length >= 1,
      true,
      'Search by $diacriticQuery expected at least 1 group',
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

    // Open a group from the search result and confirm the detail screen shows.
    await _search(searchByTitle);
    final toOpen = await robots.chatListRobot().getListOfChatGroup();
    s.softAssertEquals(
      toOpen.isNotEmpty,
      true,
      'No group to open for $searchByTitle',
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

  @override
  Future<void> runTestLogic() async {
    final now = DateTime.now();
    // Non-numeric body so the message preview is never mis-read as the count.
    final body = 'unread probe ${now.hour}:${now.minute}:${now.second}';

    await robots.homeRobot().gotoChatListScreen();
    final (groupTitle, roomId) = await _resolveGroupFixture(this);

    final before = _readUnread(groupTitle);
    await sendMessageAsReceiver(message: body, roomId: roomId);
    final after = await _pollUnreadChange(groupTitle, before);

    expect(
      after - before == 1,
      isTrue,
      reason: 'expected the difference to be 1 but before=$before after=$after',
    );
  }

  int _readUnread(String title) =>
      robots.chatListRobot().getUnreadMessage(title);

  /// Polls until the unread count differs from [from] (the receive is async —
  /// the badge only updates after the next /sync), then returns it.
  Future<int> _pollUnreadChange(String title, int from) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    var current = from;
    while (DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 300));
      current = _readUnread(title);
      if (current != from) break;
    }
    return current;
  }
}

/// Cross-platform scenario: the unread badge clears once the room is viewed at
/// the live bottom.
///
/// Guards the read-marker behaviour introduced by this change: arriving at the
/// bottom of the timeline fires `setReadMarker(eventId: null)`, which must mark
/// the room read and drop the chat-list badge back to zero. With the
/// per-message VisibilityDetector logic removed, the at-bottom transition is
/// now the sole mechanism that clears the badge, so a regression here surfaces
/// as the badge staying non-zero.
class UnreadBadgeClearsScenario extends BaseTestScenario {
  UnreadBadgeClearsScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final now = DateTime.now();
    // Non-numeric body so the message preview is never mis-read as the count.
    final body = 'read probe ${now.hour}:${now.minute}:${now.second}';

    await robots.homeRobot().gotoChatListScreen();
    final (groupTitle, roomId) = await _resolveGroupFixture(this);

    // Make the room unread first, and confirm the badge actually went up —
    // otherwise the clear-to-zero assertion below would pass vacuously.
    await sendMessageAsReceiver(message: body, roomId: roomId);
    final unread = await _pollUnread(groupTitle, (count) => count >= 1);
    expect(
      unread >= 1,
      isTrue,
      reason: 'expected the unread badge to increment, got $unread',
    );

    // Open the room and arrive at the live bottom, which is what marks it read.
    final chatList = robots.chatListRobot();
    await chatList.openChatByTitle(groupTitle);
    final detail = robots.chatGroupDetailRobot();
    await detail.confirmAccessMedia();
    await detail.scrollToLiveBottom();
    await detail.clickOnBackIcon();

    // The receipt is sent on the at-bottom transition and the badge only clears
    // after the next /sync, so poll until it drops to zero.
    final cleared = await _pollUnread(groupTitle, (count) => count == 0);
    expect(
      cleared,
      0,
      reason:
          'expected the unread badge to clear after viewing the room at '
          'the live bottom, got $cleared',
    );
  }

  int _readUnread(String title) =>
      robots.chatListRobot().getUnreadMessage(title);

  /// Polls the unread badge (which only updates after the next /sync) until
  /// [done] holds or the deadline passes, then returns the last value read.
  Future<int> _pollUnread(String title, bool Function(int) done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    var current = _readUnread(title);
    while (!done(current) && DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 300));
      current = _readUnread(title);
    }
    return current;
  }
}

/// Cross-platform scenario: pin then unpin a chat.
class PinChatScenario extends BaseTestScenario {
  PinChatScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();
    final (groupTitle, _) = await _resolveGroupFixture(this);

    await robots.chatListRobot().pinChat(groupTitle);
    expect(
      await robots.chatListRobot().isChatPinned(groupTitle),
      isTrue,
      reason: 'Expected "$groupTitle" to be pinned',
    );

    await robots.chatListRobot().unpinChat(groupTitle);
    expect(
      await robots.chatListRobot().isChatPinned(groupTitle),
      isFalse,
      reason: 'Expected "$groupTitle" to be unpinned',
    );
  }
}
