import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_bar.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/folder_edit_screen.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/folders_screen.dart';
import 'package:twake_chat/presentation/enum/settings/settings_enum.dart';

import '../base/base_test_scenario.dart';

/// Cross-platform scenario: make a folder, filter the room list by it, then
/// delete it so that a run leaves nothing on the account.
///
/// The folder takes in bots, and the test account talks to none: its chip
/// shows the empty list, which proves the filter applies.
class ManageFolderScenario extends BaseTestScenario {
  ManageFolderScenario(super.$, super.robots);

  Future<void> _openFolders() async {
    await robots.homeRobot().gotoSettingScreen();
    await $(Key(SettingEnum.chatFolders.name)).tap();
    await $.waitUntilVisible($(const ValueKey('folder_new')));
  }

  /// A new folder comes last: on a short screen it starts below the fold.
  Future<void> _scrollToFolder(String name) => $(name).scrollTo(
    view: find.descendant(
      of: find.byType(FoldersScreen),
      matching: find.byType(ReorderableListView),
    ),
  );

  Future<void> _goBack() async {
    await $(find.byTooltip('Back').last).tap();
    await $.pumpAndSettle();
  }

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();
    final name = 'Folder ${DateTime.now().millisecondsSinceEpoch}';

    await _openFolders();
    await $(const ValueKey('folder_new')).tap();
    await $(const ValueKey('folder_name')).enterText(name);
    await $(const ValueKey('folder_type_bot')).tap();
    // Web shows the room list beside the form: scroll the form, not the first
    // scrollable found.
    await $(const ValueKey('folder_save')).scrollTo(
      view: find.descendant(
        of: find.byType(FolderEditScreen),
        matching: find.byType(CustomScrollView),
      ),
    );
    await $(const ValueKey('folder_save')).tap();
    await _scrollToFolder(name);
    await _goBack();

    try {
      await robots.homeRobot().gotoChatListScreen();
      await $(name).scrollTo(
        view: find.descendant(
          of: find.byType(RoomListFilterBar),
          matching: find.byType(Scrollable),
        ),
      );
      await $(name).tap();
      await $.waitUntilVisible($('Nothing here.'));
    } finally {
      // Leave nothing behind on the shared account, whatever failed.
      await _deleteFolder(name);
    }
  }

  Future<void> _deleteFolder(String name) async {
    await _openFolders();
    await _scrollToFolder(name);
    await $(
      find.descendant(
        of: find.ancestor(
          of: find.text(name),
          matching: find.byType(LinagoraSettingItem),
        ),
        matching: find.byTooltip('Delete folder'),
      ),
    ).tap();
    await $('Delete').tap();
    await $.pumpAndSettle();
    expect($(name).exists, isFalse, reason: 'The folder was not deleted');
  }
}
