import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_bar.dart';
import 'package:twake_chat/pages/chat/chat_view.dart';

import '../base/base_test_scenario.dart';
import '../robots/add_member_robot.dart';
import '../robots/setting_for_new_group.dart';

/// Cross-platform scenario: create a space, then a group inside it, through
/// the flow of a new group: its members, then its details.
class CreateSpaceScenario extends BaseTestScenario {
  CreateSpaceScenario(super.$, super.robots);

  static const _memberSearchKey = String.fromEnvironment(
    'SearchByMatrixAddress',
  );

  Future<void> _fillTheFlow(String name) async {
    await AddMemberRobot($).makeASearch(_memberSearchKey);
    await AddMemberRobot($).selectAllFilteredAccounts();
    await AddMemberRobot($).clickOnNextIcon();
    await SettingForNewGroupRobot($).settingForNewGroup(name);
    await SettingForNewGroupRobot($).getConfirmIcon().tap();
  }

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();
    final now = DateTime.now().millisecondsSinceEpoch;
    final spaceName = 'Space $now';
    final groupName = 'Group $now';

    await robots.chatListRobot().clickOnPenIcon();
    await $('New space').tap();
    await _fillTheFlow(spaceName);

    await $.waitUntilVisible($(const ValueKey('space_new_group')));
    expect($('Private space').exists, isTrue, reason: 'Space home not shown');
    await $.waitUntilVisible($('General'));

    await $(const ValueKey('space_new_group')).tap();
    await _fillTheFlow(groupName);
    await $.waitUntilVisible($(ChatView));

    // A phone shows the conversation alone: go back to the list.
    const RoomsRoute().go($.tester.element(find.byType(Scaffold).first));
    await $('Spaces').scrollTo(
      view: find.descendant(
        of: find.byType(RoomListFilterBar),
        matching: find.byType(Scrollable),
      ),
    );
    await $('Spaces').tap();
    await $.waitUntilVisible($(groupName));

    // Earlier runs left their own spaces, each with a « General »: the rows
    // under THIS space are the ones that count. The list shows a space, then
    // its children one level deeper.
    final rows = $.tester
        .widgetList<ChatListItem>(find.byType(ChatListItem))
        .toList();
    final spaceAt = rows.indexWhere(
      (row) => row.space != null && row.room.name == spaceName,
    );
    expect(spaceAt, isNonNegative, reason: 'The space is not listed');
    final children = rows
        .skip(spaceAt + 1)
        .takeWhile((row) => row.depth > rows[spaceAt].depth)
        .map((row) => row.room.name);
    expect(children, containsAll(['General', groupName]));

    // Spaces show in All: leave nothing behind on the shared account.
    final created = rows
        .skip(spaceAt)
        .take(children.length + 1)
        .map((row) => row.room);
    for (final room in created.toList().reversed) {
      await room.leave();
    }
  }
}
