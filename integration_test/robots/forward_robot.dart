import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/pages/forward/forward_recent_chat_list.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

/// Robot for interacting with the Forward screen.
class ForwardRobot extends CoreRobot {
  ForwardRobot(super.$);

  L10n get _l10n {
    // ForwardView is on-screen when this robot is active; grab context from it.
    final elements = find.byType(ForwardView).evaluate();
    if (elements.isNotEmpty) {
      return L10n.of(elements.first)!;
    }
    // Fallback to first Scaffold context.
    return L10n.of($.tester.element(find.byType(Scaffold).first))!;
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PatrolFinder getBackIcon() => $(AppBar).$(TwakeIconButton).$(Icon);

  // ── Chat list items ───────────────────────────────────────────────────────

  /// Returns every room row rendered by [ForwardRecentChatList].
  PatrolFinder getChatItems() => $(ForwardRecentChatList).$(Material);

  /// Returns the row whose title text contains [roomName].
  PatrolFinder getChatItemByName(String roomName) => $(ForwardRecentChatList)
      .$(Material)
      .containing(
        $(ChatListItemTitle).containing(find.textContaining(roomName)),
      );

  /// Reads the [Checkbox.value] for the row identified by [roomName].
  bool isChatSelected(String roomName) {
    final item = getChatItemByName(roomName);
    if (!item.exists) return false;
    final checkbox = $.tester.widget<Checkbox>(
      find.descendant(of: item.finder, matching: find.byType(Checkbox)),
    );
    return checkbox.value ?? false;
  }

  /// Taps the row to toggle selection.
  Future<void> selectChatByName(String roomName) async {
    await getChatItemByName(roomName).tap();
    await $.pump(const Duration(milliseconds: 300));
  }

  // ── Send / Forward button ─────────────────────────────────────────────────

  /// Send FAB (mobile – TwakeIconButton with send tooltip).
  PatrolFinder getSendButton() =>
      $(TwakeIconButton).containing(find.byTooltip(_l10n.send));

  /// Web/tablet "Forward" text button (labeled via [L10n.add]).
  PatrolFinder getWebForwardButton() => $(find.text(_l10n.add));

  /// Taps the send / forward button. Works on both mobile and web layout.
  Future<void> tapSendButton() async {
    // On mobile the FAB only appears after at least one room is selected.
    // Wait for it explicitly before tapping to avoid Patrol's internal
    // waitUntilVisible eating into the global test timeout.
    final fab = getSendButton();
    final webBtn = getWebForwardButton();
    if (fab.exists || !webBtn.exists) {
      await $.waitUntilVisible(fab, timeout: const Duration(seconds: 10));
      await $.tester.tap(fab.finder);
    } else {
      await $.tester.tap(webBtn.finder);
    }
    await $.pump(const Duration(milliseconds: 500));
    await $.pumpAndSettle();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  /// The search [TextField] inside [SearchableAppBar].
  ///
  /// On mobile (`isFullScreen=true`) the field is hidden until the search icon
  /// is tapped.  On web the field is always visible.
  PatrolFinder getSearchField() => $(SearchableAppBar).$(TextField);

  /// Opens the search bar (if needed) and types [query].
  ///
  /// After entering text we pump briefly so the filter debounce can run.
  Future<void> searchRoom(String query) async {
    // Search icon has tooltip L10n.search – tap it to reveal the TextField.
    final searchIcon = $(
      SearchableAppBar,
    ).$(TwakeIconButton).containing(find.byTooltip(_l10n.search));
    if (searchIcon.exists) {
      // Use tester.tap to skip Patrol's internal waitUntilVisible overhead.
      await $.waitUntilVisible(searchIcon, timeout: const Duration(seconds: 5));
      await $.tester.tap(searchIcon.finder);
      await $.pump(const Duration(milliseconds: 300));
    }

    final field = getSearchField();
    await $.waitUntilVisible(field, timeout: const Duration(seconds: 5));
    // Use tester.enterText directly — Patrol's enterText re-checks
    // hit-testability which fails on iOS when the keyboard shifts the layout.
    await $.tester.enterText(field.finder, query);
    await $.pump(const Duration(milliseconds: 600));
  }

  /// Clears the search field to restore the full room list.
  Future<void> clearSearch() async {
    final closeIcon = $(
      SearchableAppBar,
    ).$(TwakeIconButton).containing(find.byTooltip(_l10n.close));
    if (closeIcon.exists) {
      await closeIcon.tap();
      await $.pump(const Duration(milliseconds: 300));
    }
  }

  // ── Assertions ────────────────────────────────────────────────────────────

  /// Waits until [ForwardView] (or [ForwardRecentChatList]) is in the tree.
  ///
  /// Uses the widget type rather than AppBar text so that it works even when
  /// the AppBar is not hit-testable (Patrol's visibility check ignores widgets
  /// whose render-box cannot receive pointer events).
  Future<void> verifyForwardScreenVisible() async {
    // ForwardRecentChatList is always rendered inside ForwardView even when
    // the room list is empty – the ForwardView Scaffold is the safe anchor.
    await $.waitUntilVisible(
      $(ForwardView),
      timeout: const Duration(seconds: 15),
    );
    expect($(ForwardView).exists, isTrue);
  }

  /// Waits until the row for [roomName] is visible in the list.
  Future<void> verifyRoomInList(String roomName) async {
    await $.waitUntilVisible(
      getChatItemByName(roomName),
      timeout: const Duration(seconds: 10),
    );
    expect(getChatItemByName(roomName).exists, isTrue);
  }

  /// Asserts the checkbox for [roomName] is checked.
  void verifyRoomSelected(String roomName) {
    expect(
      isChatSelected(roomName),
      isTrue,
      reason: '"$roomName" should be selected',
    );
  }

  /// Asserts the checkbox for [roomName] is unchecked.
  void verifyRoomNotSelected(String roomName) {
    expect(
      isChatSelected(roomName),
      isFalse,
      reason: '"$roomName" should NOT be selected',
    );
  }
}
