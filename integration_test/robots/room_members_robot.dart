import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/chat_details_edit_view.dart';
import 'package:twake_chat/pages/chat_details/chat_details_view.dart';
import 'package:twake_chat/pages/chat_details/participant_list_item/mobile_context_menu_overlay.dart';
import 'package:twake_chat/pages/chat_details/removed/removed_view.dart';

import '../base/core_robot.dart';

const _serverTimeout = Duration(seconds: 30);

/// The members tab of Group info, its long-press menu and the Removed Users
/// page reached from Edit.
class RoomMembersRobot extends CoreRobot {
  RoomMembersRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).last))!;

  PatrolFinder member(String matrixId) =>
      $(ChatDetailsView).$(find.byKey(ValueKey<String>(matrixId)));

  Future<void> expectMember(String matrixId) =>
      $.waitUntilVisible(member(matrixId), timeout: _serverTimeout);

  Future<void> expectNoMember(String matrixId) =>
      waitUntilAbsent($, member(matrixId), timeout: _serverTimeout);

  Future<void> expectRole(String matrixId, String role) =>
      $.waitUntilVisible(member(matrixId).$(role), timeout: _serverTimeout);

  Future<void> _chooseFromMenu(String matrixId, String action) async {
    await expectMember(matrixId);
    await member(matrixId).longPress();
    // The menu is pushed on its own route, above the overlay.
    await $.waitUntilExists($(MobileContextMenuOverlay));
    final item = $(action).last;
    await $.waitUntilVisible(item);
    await item.tap();
  }

  Future<void> promoteToAdmin(String matrixId) async {
    await _chooseFromMenu(matrixId, _l10n.promoteToAdmin);
    await expectRole(matrixId, _l10n.admin);
  }

  /// Starts the selection from the first member's menu, then taps the others.
  Future<void> removeTogether(List<String> matrixIds) async {
    await _chooseFromMenu(matrixIds.first, _l10n.select);
    for (final matrixId in matrixIds.skip(1)) {
      await member(matrixId).tap();
    }
    await $(ChatDetailsView).$(_l10n.removeMember).tap();
    for (final matrixId in matrixIds) {
      await expectNoMember(matrixId);
    }
  }

  Future<void> openRemovedUsers() async {
    await $(
      ChatDetailsView,
    ).$(TextButton).containing(find.text(_l10n.edit)).tap();
    await $.waitUntilVisible($(ChatDetailsEditView));
    await $(ChatDetailsEditView).$(_l10n.removedUsers).scrollTo().tap();
    await $.waitUntilVisible($(RemovedView));
  }

  PatrolFinder _removedRow(String displayName) =>
      $(RemovedView).$(TwakeListItem).containing(find.text(displayName));

  Future<void> unban(String displayName) async {
    await $.waitUntilVisible(_removedRow(displayName), timeout: _serverTimeout);
    await _removedRow(displayName).$(_l10n.unban).tap();
    await waitUntilAbsent($, _removedRow(displayName), timeout: _serverTimeout);
  }
}
