import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/message_content.dart';
import 'package:twake_chat/pages/forward/forward_view.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../base/core_robot.dart';
import 'abstract/abstract_message_menu_robot.dart';
import 'menu_robot.dart';
import 'message_selection_appbar_helper.dart';

/// Mobile message action menu.
///
/// Long-pressing a message bubble opens a `PullDownMenu` overlay whose items
/// are `PullDownMenuItem`s, located via [PullDownMenuRobot]. This robot is only
/// wired into `MobileRobotFactory`, so `$.native.*` calls are never compiled
/// into the web build.
class MessageMenuRobot extends CoreRobot implements AbstractMessageMenuRobot {
  MessageMenuRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).last))!;

  PullDownMenuRobot get _menu => PullDownMenuRobot($);

  Future<void> _openMenu(String message) async {
    // The app ignores long-presses while the event is still `isSending`
    // (`MultiPlatformSelectionMode.onLongPress` is null until the server
    // acks). Waiting only for the bubble to be *visible* races that ack, so
    // press until the menu actually opens.
    final messageFinder = $(
      MessageContent,
    ).containing(find.textContaining(message));
    final menu = $(PullDownMenu);
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!menu.exists && DateTime.now().isBefore(deadline)) {
      await messageFinder.longPress();
      await $.pump(const Duration(milliseconds: 700));
    }
    await $.waitUntilVisible(menu, timeout: const Duration(seconds: 15));
    await $.pump();
  }

  @override
  Future<void> openForward(String message) async {
    await _openMenu(message);
    await _menu.getForwardItem().tap();
    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndTrySettle();
    await $.waitUntilExists(
      $(ForwardView),
      timeout: const Duration(seconds: 15),
    );
  }

  @override
  Future<void> openReply(String message) async {
    await _openMenu(message);
    await _menu.getReplyItem().tap();
    await $.pump(const Duration(milliseconds: 300));
  }

  @override
  Future<void> openDelete(String message) async {
    await _openMenu(message);
    await _menu.getDeleteItem().tap();
    final dialog = $(find.byKey(TwakeDialog.showConfirmAlertDialogKey));
    final delete = dialog.$(find.text(_l10n.delete));
    await $.waitUntilVisible(delete);
    await delete.tap();
    await $.pump(const Duration(milliseconds: 300));
  }

  @override
  Future<void> openEdit(String message) async {
    await _openMenu(message);
    await _menu.getEditItem().tap();
    await $.pump(const Duration(milliseconds: 300));
  }

  @override
  Future<void> openSelect(String message) async {
    await _openMenu(message);
    await _menu.getSelectItem().tap();
    await $.pump(const Duration(milliseconds: 300));
  }

  @override
  Future<void> openMessageInfo(String message) async {
    await openSelect(message);
    await openMessageInfoFromSelectionAppBar($, _l10n);
  }
}
