import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_details.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../base/core_robot.dart';
import 'abstract/abstract_chat_group_detail_robot.dart';
import 'menu_robot.dart';

class ChatGroupDetailRobot extends CoreRobot
    implements AbstractChatGroupDetailRobot {
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

  @override
  String getTotalMemberLabel() {
    final a = $(ChatAppBarTitle).$(find.textContaining('member')).text;
    return a!.replaceFirst(RegExp(r'\s+m.*$', caseSensitive: false), '');
  }

  @override
  String? getTitle() {
    // The avatar renders the room's fallback initial as the first `Text` in
    // `ChatAppBarTitle`; scope to the `Expanded` title column so we read the
    // room name and not the avatar letter.
    return $(ChatAppBarTitle).$(Expanded).$(Text).at(0).text;
  }

  @override
  Future<void> tapOnChatBarTitle() async {
    await getChatAppBarTitle().tap();
    await $.waitUntilVisible($("Group info"));
  }

  @override
  Future<void> tapOnChatBarTitleForDM() async {
    await getChatAppBarTitle().tap();
    // For DM chats, wait for the profile info details widget instead of "Group information"
    await $.waitUntilVisible($(ChatProfileInfoDetails));
  }

  @override
  Future<void> confirmAccessMedia() async {
    if (PlatformInfos.isAndroid) return;
    final dialog = $(PermissionDialog);
    try {
      await dialog.waitUntilVisible(timeout: const Duration(seconds: 3));
      if (dialog.exists) {
        final ctx = $.tester.element(dialog); // BuildContext inside dialog
        final nextLabel = L10n.of(ctx)!.next; // whatever the app shows

        await $.tester.tap(
          find.descendant(of: dialog, matching: find.text(nextLabel)),
        );
        await $.tester.pumpAndSettle();
      }
    } catch (e) {
      ignoreException();
    }
  }

  @override
  Future<bool> isVisible() async {
    await $.waitUntilVisible($(ChatEventList));
    return $(ChatEventList).exists;
  }

  @override
  Future<PatrolFinder> getText(String text) async {
    // Text messages render through a linkified RichText (`TwakeLinkPreview`),
    // so match rich text too — on web the body is not a plain `Text` widget.
    return $(
      MessageContent,
    ).containing(find.textContaining(text, findRichText: true));
  }

  Future<PatrolFinder> getInputTextField() async {
    // Scope to the composer's `InputBar`. On web's wide two-pane layout the
    // chat-list search field is also a `TextField`, so a bare `$(TextField)`
    // resolves to the wrong field.
    return $(InputBar).$(TextField);
  }

  @override
  Future<void> inputMessage(String message) async {
    final textField = await getInputTextField();
    // catch exception when trying to chat with non-existing account
    await CoreRobot($).captureAsyncError(() async {
      await textField.tap();
    });
    // Type slowly so the composer's `inputText` ValueListenable updates — a
    // plain `enterText` does not fire `onChanged` on web, leaving the send
    // button hidden (web renders the audio recorder while the text is empty).
    await typeSlowlyWithPatrol($, textField, message);
  }

  @override
  Future<void> sendMessage(String message) async {
    await inputMessage(message);
    // Wait for the send button to surface before tapping — on web the composer
    // swaps the audio recorder for the send button only once `onChanged` fires,
    // so an immediate tap can race the composer update and miss the target.
    await $.waitUntilVisible($(ChatInputRowSendBtn));
    await $(ChatInputRowSendBtn).tap();
    await $.pump(const Duration(milliseconds: 300));
  }

  @override
  Future<void> clickOnBackIcon() async {
    await goBack();
  }

  @override
  Future<void> scrollToLiveBottom() async {
    // Drag the timeline to its bottom deterministically rather than relying on
    // the scroll-down FAB (which only shows while scrolled up, and whose
    // appearance races the async timeline load on web). The list is not
    // reversed — the live bottom is at `maxScrollExtent` — so dragging up until
    // the scroll position stops moving lands exactly there, which is the
    // transition that fires the read marker. A room that already opens at the
    // bottom needs no movement and exits on the first no-op drag.
    await isVisible(); // waits for the ChatEventList timeline to mount
    await scrollToBottom($, root: $(ChatEventList));
    await $.pump(const Duration(milliseconds: 500));
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
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // 1) Chờ xuất hiện (ngay sau hành động tạo room)
    await $.waitUntilVisible($(message), timeout: timeout);

    // 2) (tuỳ chọn) Chờ nó biến mất để tránh flakiness cho bước sau
    await waitUntilAbsent($, $(message));
  }
}
