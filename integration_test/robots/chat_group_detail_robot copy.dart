import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/chat_input_row.dart';
import 'package:fluffychat/pages/chat/events/message/swipeable_message.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/chat/events/message_video_download_content.dart';
import 'package:fluffychat/widgets/file_widget/downloading_file_tile_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../base/core_robot.dart';
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

  List<TwakeListItemRobot> getAllImageMessages() {
    final count = $(SwipeableMessage).containing($(Image)).evaluate().length;
    return List.generate(count, (i) => TwakeListItemRobot($, $(SwipeableMessage).at(i)));
  }

  TwakeListItemRobot getTheLastestImageMsg() {
    final List<TwakeListItemRobot> messages = getAllImageMessages();
    return messages.first;
  }

  List<TwakeListItemRobot> getAllVideoMessages() {
    final count = $(SwipeableMessage).containing($(MessageVideoDownloadContent)).evaluate().length;
    return List.generate(count, (i) => TwakeListItemRobot($, $(SwipeableMessage).at(i)));
  }

  TwakeListItemRobot getTheLastestVideoMsg() {
    final List<TwakeListItemRobot> messages = getAllVideoMessages();
    return messages.first;
  }

  List<TwakeListItemRobot> getAllFileMessages() {
    final list = $(SwipeableMessage).containing($(DownloadingFileTileWidget));
    final n = list.evaluate().length;
    // return List.generate(count, (i) => TwakeListItemRobot($, $(SwipeableMessage).at(i)));
      return List.generate(n, (i) => TwakeListItemRobot($, list.at(i)));
  }

  TwakeListItemRobot getTheLastestFileMsg() {
    final List<TwakeListItemRobot> messages = getAllFileMessages();
    return messages.first;
  }

  TwakeListItemRobot getFileMsg(String fileName) {
    final msgs = $(SwipeableMessage);
    for (int i = msgs.evaluate().length - 1; i >= 0; i--) {
      if (msgs.at(i).$(RichText).evaluate().any(
        (e) => (e.widget as RichText).text.toPlainText().contains(fileName),
      )) {
        return TwakeListItemRobot($, msgs.at(i));
      }
    }
    throw StateError('There is no "$fileName".');
  }

  Future<void> tapOnChatBarTitle() async {
    await getChatAppBarTitle().tap();
    await $.waitUntilVisible($("Group information"));
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

  Future<PullDownMenuRobot> openPullDownMenuOfAPatrolFinder(PatrolFinder message) async {
    await message.longPress();
    await $.waitUntilVisible($(PullDownMenu));
    await $.pump();
    return PullDownMenuRobot($);
  }

  Future<PullDownMenuRobot> openPullDownMenuOfAMessage(String message) async {
    final patrFinder = $(MessageContent).containing(find.text(message));
    return await openPullDownMenuOfAPatrolFinder(patrFinder);
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
}
