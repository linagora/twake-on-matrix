import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/chat_input_row.dart';
import 'package:fluffychat/pages/chat/events/message/swipeable_message.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../base/core_robot.dart';
import '../help/attach_file_ios_test.dart';
import 'menu_robot.dart';
import 'twake_list_item_robot.dart';

class ChatGroupDetailRobot extends CoreRobot {
  ChatGroupDetailRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(AppBar).$(TwakeIconButton).$(Icon);
  }

  PatrolFinder getSearchIcon() {
    return $(AppBar).$(IconButton);
  }
  PatrolFinder getMoreIconInAppBar() {
    return $(AppBar).containing(find.byTooltip('More'));
  } 
  PatrolFinder getMoreIcon() {
    return $(TwakeIconButton).containing(find.byTooltip('More'));
  }

  PatrolFinder getChatAppBarTitle() {
    return $(ChatAppBarTitle);
  }

  String getTotalMemberLabel() {
    final a = $(ChatAppBarTitle).$(find.textContaining('member')).text;
    return a!.replaceFirst(RegExp(r'\s+m.*$', caseSensitive: false), '');
  }

  String? getTitle() {
    return $(ChatAppBarTitle).$(Text).at(0).text;
  }

  PatrolFinder getMoreMessageIcon() {
    return $(ChatInputRow).$(TwakeIconButton).containing(find.byTooltip('More'));
  }

  List<TwakeListItemRobot> getAllMessages() {
    final count = $(SwipeableMessage).evaluate().length;
    return List.generate(count, (i) => TwakeListItemRobot($, $(SwipeableMessage).at(i)));
  }

  TwakeListItemRobot getTheLastestMessage() {
    final List<TwakeListItemRobot> messages = getAllMessages();
    return messages.first;
  }
  
  Future<void> tapOnChatBarTitle() async {
    await getChatAppBarTitle().tap();
    await $.waitUntilVisible($("Group information"));
  }

  Future<void> confimrAccessMedia() async {
    final dialog = $(PermissionDialog);
    try {
      await dialog.waitUntilVisible(timeout: const Duration(seconds: 3));
      if (dialog.exists) {
        final ctx = $.tester.element(dialog); // BuildContext inside dialog
        final nextLabel = L10n.of(ctx)!.next; // whatever the app shows

        await $.tester
            .tap(find.descendant(of: dialog, matching: find.text(nextLabel)));
        await $.tester.pumpAndSettle();
      }
    } catch (e) {
      ignoreException();
    }
  }

  Future<bool> isVisible() async {
    await $.waitUntilVisible($(ChatEventList));
    return $(ChatEventList).exists;
  }

  Future<PatrolFinder> getText(String text) async {
    return $(MessageContent).containing(find.text(text));
  }

  PatrolFinder getInputTextField() {
    return $(TextField);
  }

  Future<void> inputMessage(String message) async {
    final textField = getInputTextField();
    // catch exception when trying to chat with non-existing account
    await CoreRobot($).captureAsyncError(() async {
        await textField.tap();
      });
    await textField.enterText(message);
  }

  Future<void> clickOnBackIcon() async {
    await getBackIcon().tap();
  }

  Future<PullDownMenuRobot> openPullDownMenu(String message) async {
    await $(MessageContent).containing(find.text(message)).longPress();
    await $.waitUntilVisible($(PullDownMenu));
    await $.pump();
    return PullDownMenuRobot($);
  }

  Future<void> closePullDownMenu() async {
    await PullDownMenuRobot($).close();
  }

  Future<void> expectSnackShown(
    PatrolIntegrationTester $, {
    String message = 'Room creation failed',
    }) async {
      final snackText =
          $(find.textContaining(message, findRichText: true)).first;

      await $.waitUntilVisible(snackText, timeout: const Duration(seconds: 5));

      await waitUntilAbsent($, snackText);
  }

  Future<void> openAttachDialog() async {
    await getMoreMessageIcon().tap();
    if($(PermissionTextButton).containing('Next').exists)
    {
      await $.waitUntilVisible($(PermissionTextButton).containing('Next'));
      await $(PermissionTextButton).containing('Next').tap();
      await ChatGroupDetailRobot($).waitUntilAbsent($, $(PermissionTextButton).containing('Next'));
    }    
    await allowPhotosIfNeeded($);
  }
}
