import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import '../base/core_robot.dart';

class ChatGroupDetailRobot extends CoreRobot {
  ChatGroupDetailRobot(super.$);

  Future<PatrolFinder> getBackIcon() async {
    return $(AppBar).$(TwakeIconButton).$(Icon);
  }
  
  Future<void> confimrAccessMedia() async {
    final dialog = $(PermissionDialog);
    try{
      await dialog.waitUntilVisible(timeout: const Duration(seconds: 3));
      if ( dialog.exists) {    
        final ctx = $.tester.element(dialog);          // BuildContext inside dialog
        final nextLabel = L10n.of(ctx)!.next;          // whatever the app shows

        await $.tester.tap(find.descendant(of: dialog, matching: find.text(nextLabel)));
        await $.tester.pumpAndSettle();
      }
    }
    catch (e) {
      ignoreException();
    }
  }

  Future<bool> isVisible() async {
    final chatListSelector = $(ChatEventList);
    try {
      await chatListSelector.waitUntilVisible(timeout: const Duration(seconds: 120));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PatrolFinder> getText(String text) async {
    return $(MatrixLinkifyText).containing(text);
  }

  Future<PatrolFinder> getInputTextField() async {
    return $(TextField);
  }

  Future<void> inputMessage(String message) async {
    await getInputTextField().tap();
    await getInputTextField().enterText(message);
  }

  Future<void> backToPreviousScreen() async{
    await getBackIcon().tap();
  }
}
