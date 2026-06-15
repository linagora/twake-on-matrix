import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../base/core_robot.dart';
import 'abstract/abstract_message_menu_robot.dart';
import 'menu_robot.dart';

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
    await $(MessageContent).containing(find.text(message)).longPress();
    await $.waitUntilVisible($(PullDownMenu));
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
    // The deletion confirmation surfaces as a native dialog on mobile.
    await $.native.tap(Selector(text: _l10n.delete));
    await $.pump(const Duration(milliseconds: 300));
  }
}
