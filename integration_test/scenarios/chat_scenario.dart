import 'dart:developer';
import 'dart:io';
import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_input_row.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_events_view.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_screen.dart';
import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat/event_info_dialog.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/pages/chat/seen_by_row.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body_view.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/add_member_robot.dart';
import '../robots/chat_group_detail_robot.dart';
import '../robots/chat_list_robot.dart';
import 'package:flutter/material.dart';
import '../robots/group_information_robot.dart';
import '../robots/menu_robot.dart';
import '../robots/new_chat_robot.dart';
import '../robots/search_robot.dart';
import '../robots/setting_for_new_group.dart';
import '../robots/twake_list_item_robot.dart';

enum UserLevel { member, admin, owner, moderator }

class ChatScenario extends CoreRobot {
  ChatScenario(super.$);

  Future<void> enterSearchText(String searchText) async {
    await SearchRobot($).enterSearchText(searchText);
    await $.pump();
  }

  Future<ChatGroupDetailRobot> openChatGroupByTitle(String groupTitle) async {
    await enterSearchText(groupTitle);
    await (await ChatListRobot($).getListOfChatGroup())[0].root.tap();
    await $.pumpAndSettle();
    return ChatGroupDetailRobot($);
  }

  Future<ChatGroupDetailRobot> openGroupChatInfo() async {
    await (ChatGroupDetailRobot($).tapOnChatBarTitle());
    return ChatGroupDetailRobot($);
  }

  Future<int> addMembers(List<String> members) async {
    await openGroupChatInfo();
    await GroupInformationRobot($).clickOnAddMemberBtn();
    for (final member in members) {
      await AddMemberRobot($).makeASearch(member);
      await AddMemberRobot($).selectAllFilteredAccounts();
    }
    await AddMemberRobot($).getNextIcon().tap();
    await AddMemberRobot($).getAgreeInviteMemberBtn().tap();
    await $.waitUntilVisible($("Group information"));
    return (await GroupInformationRobot($).getListOfMembers()).length;
  }

  Future<int> removeMembers(List<String> members) async {
    await openGroupChatInfo();
    for (final member in members) {
      await GroupInformationRobot($).getMember(member).tap();
      await GroupInformationRobot($).clickOnRemoveFromGroup();
      await GroupInformationRobot($).clickOnAgreeIRemoveMemberBtn();
    }
    await $.waitUntilVisible($("Group information"));
    return (await GroupInformationRobot($).getListOfMembers()).length;
  }

  Future<void> backToChatLisFromChatGroupScreen({
    bool isOpenGroupFromSearchResult = false,
  }) async {
    await ChatGroupDetailRobot($).clickOnBackIcon();
    if (isOpenGroupFromSearchResult) {
      await SearchRobot($).backToPreviousScreen();
    }
  }

  Future<void> verifyTheDisplayOfPullDownMenu(
    String message, {
    UserLevel level = UserLevel.member,
  }) async {
    expect((PullDownMenuRobot($).getReplyItem()).exists, isTrue);
    expect((PullDownMenuRobot($).getForwardItem()).exists, isTrue);
    expect((PullDownMenuRobot($).getCopyItem()).exists, isTrue);
    if (level == UserLevel.owner ||
        level == UserLevel.admin ||
        level == UserLevel.moderator) {
      expect((PullDownMenuRobot($).getEditItem()).exists, isTrue);
    } else {
      expect((PullDownMenuRobot($).getEditItem()).exists, isFalse);
    }
    expect((PullDownMenuRobot($).getSelectItem()).exists, isTrue);
    expect((PullDownMenuRobot($).getPinItem()).exists, isTrue);
    expect((PullDownMenuRobot($).getDeleteItem()).exists, isTrue);
    expect((PullDownMenuRobot($).getHeartIcon()).exists, isTrue);
    expect((PullDownMenuRobot($).getLikeIcon()).exists, isTrue);
    expect((PullDownMenuRobot($).getDisLikeIcon()).exists, isTrue);
    expect((PullDownMenuRobot($).getCryIcon()).exists, isTrue);
    expect((PullDownMenuRobot($).getSadIcon()).exists, isTrue);
    expect((PullDownMenuRobot($).getSuppriseIcon()).exists, isTrue);
    expect((PullDownMenuRobot($).getExpandIcon()).exists, isTrue);
    expect(($(MessageContent).containing(find.text(message))).exists, isTrue);
  }

  Future<void> replyMessage(String message, String reply) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (PullDownMenuRobot($).getReplyItem()).tap();
    await sendAMesage(reply);
  }

  Future<void> forwardMessage(String message, String receiver) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    await PullDownMenuRobot($).getForwardItem().tap();
  }

  Future<void> sendAMesage(String message) async {
    await ChatGroupDetailRobot($).inputMessage(message);
    // tab on send button
    await $(ChatInputRowSendBtn).tap();
    await $.pump(const Duration(milliseconds: 300));
  }

  Future<void> copyMessage(String message) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (PullDownMenuRobot($).getCopyItem()).tap();
  }

  Future<void> pasteFromClipBoard() async {
    // 1) Focus the input and open the context menu
    final input = await ChatGroupDetailRobot($).getInputTextField();
    await input.tap();
    await input.longPress();
    await $.pump(const Duration(milliseconds: 300)); // let the menu render

    // 2) Get MaterialLocalizations from the input's own context (NOT WidgetsApp)
    final BuildContext inputCtx = $.tester.element(input.finder);
    final String pasteLabel =
        MaterialLocalizations.of(inputCtx).pasteButtonLabel;

    // 3) Try Flutter tree first (Android usually)
    final flutterMenu = find.text(pasteLabel);
    final matches = flutterMenu.evaluate();
    if (matches.isNotEmpty) {
      await $.tap(
        flutterMenu.first,
      ); // tap the first match to avoid "too many elements"
      return;
    }

    // 4) iOS native UIMenu fallback
    if (Platform.isIOS) {
      try {
        await $.native.waitUntilVisible(Selector(text: pasteLabel));
        await $.native.tap(Selector(text: pasteLabel));
        return;
      } catch (_) {
        // last-resort fallback if localization text differs
        await $.native.tap(Selector(text: 'Paste'));
        return;
      }
    }

    // 5) If we reach here, the menu didn't show up or label didn't match
    throw StateError('Paste menu not found (Flutter & native).');
  }

  Future<void> editMessage(String message, String newMessage) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (PullDownMenuRobot($).getEditItem()).tap();
    await sendAMesage(newMessage);
  }

  Future<void> selectMessage(String message) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (PullDownMenuRobot($).getSelectItem()).tap();
  }

  Future<void> watchMessageInfo(String message) async {
    await selectMessage(message);
    await ChatGroupDetailRobot($).getMoreIcon().tap();
    await $.waitUntilVisible($(ContextMenuActionItemWidget).at(0));
    await ($(ContextMenuActionItemWidget).at(0)).tap();
    await $.waitUntilVisible($(EventInfoDialog));
  }

  Future<void> closeMessageInfo() async {
    await $(EventInfoDialog).$(AppBar).$(IconButton).tap();
    await $.pump();
  }

  PatrolFinder getPinExpandIcon() {
    return $(PinnedEventsView).$(TwakeIconButton).first;
  }

  Future<void> pinMessage(String message) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (PullDownMenuRobot($).getPinItem()).tap();
  }

  Future<void> unpinMessage(String message) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (PullDownMenuRobot($).getUnpinItem()).tap();
  }

  Future<void> deleteMessage(String message) async {
    await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (PullDownMenuRobot($).getDeleteItem()).tap();
    await $.native.tap(Selector(text: 'Delete'));
  }

  Future<ChatGroupDetailRobot> createANewGroupChat(
    String groupName,
    List<String> memberAccounts, {
    String searchKey = "",
  }) async {
    await ChatListRobot($).clickOnPenIcon();
    await NewChatRobot($).clickOnNewGroupChatIcon();

    if (searchKey != "") {
      await AddMemberRobot($).makeASearch(searchKey);
    }
    await AddMemberRobot($).selectAllFilteredAccounts();
    await AddMemberRobot($).clickOnNextIcon();
    await SettingForNewGroupRobot($).settingForNewGroup(groupName);
    await SettingForNewGroupRobot($).getConfirmIcon().tap();
    await $.pump(const Duration(seconds: 10));
    await $.waitUntilVisible($(ChatView));
    return ChatGroupDetailRobot($);
  }

  Future<void> createANewDirectMessage(String account) async {
    await ChatListRobot($).clickOnPenIcon();
    await NewChatRobot($).makeASearch(account);
    await NewChatRobot($).getListOfAccount()[0].root.tap();
    await CoreRobot($).waitForEitherVisible(
      $: $,
      first: $(ChatView),
      second: $(DraftChatView),
      timeout: const Duration(seconds: 30),
    );
  }

  PatrolFinder _tileByText(String text) {
    final msg =
        $(MatrixLinkifyText).containing(text); //_richTextWithExact(text);
    final container = find.ancestor(
      of: msg,
      matching: find.byType(MultiPlatformsMessageContainer),
    );
    return $(container);
  }

  Color? _effectiveIconColor(Finder iconFinder) {
    final icon = $.tester.widget<Icon>(iconFinder);
    final ctx = $.tester.element(iconFinder); // BuildContext for Icon
    return icon.color ?? IconTheme.of(ctx).color; // resolved color
  }

  Future<void> expectMessageTickSelected(
    String messageText, {
    Color? expectedColor, // e.g. const Color(0xFF0A84FF)
  }) async {
    final tile = _tileByText(messageText);
    expect(tile.exists, true);

    // 1) Find the tick icon inside this tile
    final tick = tile.$(Icon).first;
    expect(tick, findsOneWidget);

    // 2) Check color
    final color = _effectiveIconColor(tick);

    if (expectedColor != null) {
      expect(color, expectedColor);
    }
  }

  Future<void> expectMessageTickUnselected(
    String messageText, {
    Color? expectedColor, // e.g. const Color(0x000000)
  }) async {
    final tile = _tileByText(messageText);
    expect(tile.exists, true);

    // 1) Find the tick icon inside this tile
    final tick = tile.$(Icon).first;
    expect(tick, findsOneWidget);

    // 2) Check color
    final color = _effectiveIconColor(tick);

    if (expectedColor != null) {
      expect(color, expectedColor);
    }
  }

  Future<void> openPinnedPanel(PatrolIntegrationTester $) async {
    final icon = getPinExpandIcon();
    expect(icon.exists, isTrue, reason: 'Pin panel icon not found');

    await icon.tap();
    // wait for the pinned UI (a real widget on that screen)
    await $.waitUntilVisible(
      $(AppBar).containing(find.textContaining('Pinned message')),
    );
    // await $.waitUntilVisible(
    //   $(PinnedMessagesScreen).containing(find.text('Unpin all message')),
    // );

    await $.waitUntilVisible(
      $(PinnedMessagesScreen),
      timeout: const Duration(seconds: 30),
    );
    await $.waitUntilVisible(
      $(PinnedMessagesScreen)
          .containing(find.textContaining('Unpin all message')),
    );
  }

  Future<void> verifyTheDisplayInSelectedTextMode(
    String message,
    int selectedNumber,
  ) async {
    final chatInputRow = $(ChatInputRow);

    expect(
      find.descendant(of: $(AppBar).finder, matching: find.byTooltip('Close')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: $(ChatAppBarTitle).finder,
        matching: find.byTooltip('Copy'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: $(ChatAppBarTitle).finder,
        matching: find.text(selectedNumber.toString()),
      ),
      findsOneWidget,
    );
    if (selectedNumber == 1) {
      expect(
        find.descendant(
          of: $(ChatAppBarTitle).finder,
          matching: find.byTooltip('Pin'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: $(ChatAppBarTitle).finder,
          matching: find.byTooltip('More'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chatInputRow.finder, matching: find.text('Reply')),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: chatInputRow.finder, matching: find.text('Forward')),
      findsOneWidget,
    );
    await expectMessageTickSelected(
      message,
      expectedColor: const Color(0xFF0A84FF),
    );
  }

  Future<void> verifyMessageIsPinned(
    String message, {
    bool expected = true,
  }) async {
    final icon = getPinExpandIcon();

    if (!icon.exists && !expected) return;

    if (!icon.exists && expected) {
      fail('Expected pinned message but pin panel icon not found.');
    }

    await openPinnedPanel($);

    final pinnedMsg = $(MessageContent).containing(find.text(message));

    if (expected) {
      await $.waitUntilVisible(pinnedMsg);
    } else {
      expect(
        pinnedMsg.exists,
        isFalse,
        reason: 'Message is unexpectedly pinned: $message',
      );
    }
    // click back
    await ChatGroupDetailRobot($).clickOnBackIcon();
  }

  Future<void> verifySearchResultViewIsShown() async {
    expect(
      ChatListRobot($).showLessLabel().visible ||
          ChatListRobot($).noResultLabel().visible,
      isTrue,
    );
    await Future.delayed(const Duration(seconds: 5));
  }

  Future<void> verifyDisplayOfGroupListScreen(SoftAssertHelper s) async {
    s.softAssertEquals(
      (SearchRobot($).getSearchTextField()).exists,
      true,
      'Search Text Field is not visible',
    );

    // // title (avoid hard-coded text if localized)
    // final appBarCtx = $.tester.element(find.byType(TwakeAppBar));
    // final title = L10n.of(appBarCtx)!.chats; // or 'Chats' if not localized
    // s.softAssertEquals($(TwakeAppBar).containing($(Text(title))).exists,true,'Contact title is wrong',);

    s.softAssertEquals(
      $(ChatListBodyView).visible,
      true,
      'Chats tab is not visible',
    );
    s.softAssertEquals(
      $(BottomNavigationBar).visible,
      true,
      'Bottom navigator bar is not visible',
    );
  }

  Future<void> verifySearchResultContains(String keyword) async {
    final items = await ChatListRobot($).getListOfChatGroup();
    final length = items.length;
    var i = 0;

    for (final item in items) {
      i = i + 1;
      final richTextFinder = item.$(RichText);
      final richTextElements = richTextFinder.evaluate();

      if (richTextElements.isEmpty) {
        throw Exception("❌ No RichText found in item $i of $length");
      }

      // final richTextWidget = richTextElements.first.widget as RichText;
      // final text = richTextWidget.text.toPlainText();
      // log("✅ '$i' groups text '$text'");

      // if (!text.contains(keyword)) {
      //   throw Exception("❌ Group $i/$length does not contain '$keyword' -- '$text'");
      // }
    }
    log("✅ All visible chat groups contain '$keyword'");
  }

  Future<ChatGroupDetailRobot> openChatGroup(String title) async {
    await enterSearchText(title);
    await (await ChatListRobot($).getListOfChatGroup())[0].root.tap();
    final chatGroupDetailRobot = ChatGroupDetailRobot($);
    await chatGroupDetailRobot.confirmAccessMedia();
    await $.pumpAndTrySettle();
    return chatGroupDetailRobot;
  }

  Future<void> sendAMessageByAPI(String message) async {
    final client = await CoreRobot($).initialRedirectRequest();
    final list = await CoreRobot($).loginByAPI(client);
    await CoreRobot($).sendMessageByAPI(list[0], list[1], list[2], message);
    await CoreRobot($).closeHTTPClient(client);
  }

  Future<void> verifyMessageIsShown(String message, bool isTrue) async {
    final text = await ChatGroupDetailRobot($).getText(message);
    if (isTrue) {
      await $.waitUntilVisible($(text));
      expect(text, findsOneWidget);
    } else {
      await CoreRobot($).waitUntilAbsent($, text);
      expect(text, findsNothing);
    }
  }

  Future<void> verifyMessageIsSent(String message, bool isTrue) async {
    // 1) wait display of the message
    final text = await ChatGroupDetailRobot($).getText(message);
    await text.waitUntilVisible();

    // 2) get ancestor that contains message and Stack
    final bubbleStack = $(
      find.ancestor(
        of: text.finder,
        matching: find.byType(Stack),
      ),
    );

    // 3) Find SelectionContainer
    final selection = $(
      find.descendant(
        of: bubbleStack.finder,
        matching: find.byType(MessageTime, skipOffstage: false),
      ),
    );

    // 4) find SeenByRow và Icon
    final seenBy = $(
      find.descendant(
        of: selection.finder,
        matching: find.byType(SeenByRow),
      ),
    );

    // 5) find seenIcon
    final seenIcon = $(
      find.descendant(
        of: seenBy.finder,
        matching: find.byType(Icon, skipOffstage: false),
      ),
    );

    if (isTrue) {
      await seenIcon.waitUntilVisible();
      expect(seenIcon.exists, isTrue);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(seenIcon.exists, isFalse);
    }
  }

  Future<void> verifyChatListCanBeScrollable(SoftAssertHelper s) async {
    s.softAssertEquals(
      await CoreRobot($).isActuallyScrollable(
        $,
        root: $(SingleChildScrollView),
      ),
      true,
      'Chat list is not scrollable',
    );
  }

  bool isPinAChat(TwakeListItemRobot takeListItem) {
    final pin = takeListItem.getPinIcon();
    return pin.visible;
  }

  Future<void> pinAChat(String title) async {
    final twakeListItem = ChatListRobot($).getChatGroupByTitle(title);
    ChatListRobot($).scrollUntilVisible($, twakeListItem.root);

    if (!isPinAChat(twakeListItem)) {
      await $.tester.ensureVisible(twakeListItem.root);
      await twakeListItem.root.longPress();
      await $.waitUntilVisible(twakeListItem.getCheckBox());
      await ChatListRobot($).clickOnPinIcon();
    }
  }

  Future<void> unPinAChat(String title) async {
    final twakeListItem = ChatListRobot($).getChatGroupByTitle(title);
    ChatListRobot($).scrollUntilVisible($, twakeListItem.root);

    if (isPinAChat(twakeListItem)) {
      await $.tester.ensureVisible(twakeListItem.root);
      await twakeListItem.root.longPress();
      await $.waitUntilVisible(twakeListItem.getCheckBox());
      await ChatListRobot($).clickOnUnPinIcon();
    }
  }

  Future<void> verifyAChatIsPin(String title, bool isPin) async {
    final twakeListItem = ChatListRobot($).getChatGroupByTitle(title);
    await $.tester.ensureVisible(twakeListItem.root);
    final exists = isPinAChat(twakeListItem);
    expect(
      exists,
      isPin,
      reason: 'Expected pin=$isPin but got $exists for "$title"',
    );
  }
}
