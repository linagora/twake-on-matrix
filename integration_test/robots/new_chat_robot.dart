import 'package:fluffychat/pages/new_group/contacts_selection_view.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'twake_list_item_robot.dart';

class NewChatRobot extends CoreRobot {
  NewChatRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(TwakeIconButton).containing(find.byTooltip('Back'));
  }

  PatrolFinder getSearchIcon() {
    return $(TwakeIconButton).containing(find.byTooltip('Search'));
  }

  PatrolFinder getSearchField() {
    return $(TextField).first;
  }

  PatrolFinder getNewGroupChatIcon() {
    return $(InkWell).containing(find.text('New Group Chat'));
  }

  Future<void> makeASearch(String searchKey) async {
    // The new-chat screen's `SearchableAppBar` mounts its `TextField` only in
    // search mode, so activate it first. Scope the trigger to the new-chat
    // screen — on web's two-pane layout the chat-list pane has its own search
    // affordance.
    // The search `TextField` mounts only in search mode on mobile (revealed by
    // the search icon); the web new-chat shows it inline. Tap the icon only
    // when no field is present yet.
    if (!$(TextField).exists) {
      await $(find.byIcon(Icons.search)).first.tap();
    }
    await typeSlowlyWithPatrol($, getSearchField(), searchKey);
    await waitForEitherVisible(
      $: $,
      first: $(TwakeListItem),
      second: $("No Results"),
      timeout: const Duration(seconds: 10),
    );
  }

  Future<void> clickOnNewGroupChatIcon() async {
    await getNewGroupChatIcon().tap();
    // The add-members screen (`ContactsSelectionView`) opens directly in search
    // mode (`openSearchBar()` in its initState), so the standalone search icon
    // is gone and the search `TextField` is shown inline. Wait for that field
    // instead of the removed `Icons.search` affordance.
    await $.waitUntilVisible($(ContactsSelectionView).$(TextField).first);
  }

  List<TwakeListItemRobot> getListOfAccount() {
    final List<TwakeListItemRobot> groupList = [];

    final matches = $(TwakeListItem).evaluate();
    for (final element in matches) {
      final finder = $(element.widget.runtimeType);
      groupList.add(TwakeListItemRobot($, finder));
    }
    return groupList;
  }
}
