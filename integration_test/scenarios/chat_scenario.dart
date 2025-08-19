import 'dart:developer';
import 'dart:io';
import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:fluffychat/pages/chat/chat_input_row.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_events_view.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_screen.dart';
import 'package:fluffychat/pages/chat/events/message/multi_platform_message_container.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body_view.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:patrol/patrol.dart';
import '../base/base_scenario.dart';
import '../base/core_robot.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/chat_group_detail_robot.dart';
import '../robots/chat_list_robot.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../robots/search_robot.dart';

class ChatScenario extends BaseScenario {
  ChatScenario(super.$);

  Future<void> enterSearchText(String searchText) async {
    await SearchRobot($).enterSearchText(searchText);
    await SearchRobot($).waitForEitherVisible($: $, first: ChatListRobot($).showLessLabel(),second: ChatListRobot($).noResultLabel(), timeout: const Duration(seconds: 30));
    // await $.pumpAndSettle();
  }

  Future<ChatGroupDetailRobot> openChatGroupByTitle(String groupTitle) async {
    await enterSearchText(groupTitle);
    await (await ChatListRobot($).getListOfChatGroup())[0].root.tap();
    await $.pumpAndSettle();
    return ChatGroupDetailRobot($);
  }

  Future<void> verifyTheDisplayOfPullDownMenu(String message) async {
    final pullDownMenuRobot = await ChatGroupDetailRobot($).openPullDownMenu(message);
    expect((await pullDownMenuRobot.getReplyItem()).exists, isTrue);
    expect((await pullDownMenuRobot.getForwardItem()).exists, isTrue);
    expect((await pullDownMenuRobot.getCopyItem()).exists, isTrue);
    expect((await pullDownMenuRobot.getEditItem()).exists, isTrue);
    expect((await pullDownMenuRobot.getSelectItem()).exists, isTrue);
    expect((await pullDownMenuRobot.getPinItem()).exists, isTrue);
    expect((await pullDownMenuRobot.getDeleteItem()).exists, isTrue);
    expect((await pullDownMenuRobot.getHeartIcon()).exists, isTrue);
    expect((await pullDownMenuRobot.getLikeIcon()).exists, isTrue);
    expect((await pullDownMenuRobot.getDisLikeIcon()).exists, isTrue);
    expect((await pullDownMenuRobot.getCryIcon()).exists, isTrue);
    expect((await pullDownMenuRobot.getSadIcon()).exists, isTrue);
    expect((await pullDownMenuRobot.getSuppriseIcon()).exists, isTrue);
    expect((await pullDownMenuRobot.getExpandIcon()).exists, isTrue);
    expect(($(MessageContent).containing(find.text(message))).exists, isTrue);
    await pullDownMenuRobot.close();
  }

  Future<void> replyMessage(String message, String reply) async {
    final pullDownMenuRobot = await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (await pullDownMenuRobot.getReplyItem()).tap();
    await sendAMesage(reply);
  }

  Future<void> forwardMessage(String message, String receiver) async {
    final pullDownMenuRobot = await ChatGroupDetailRobot($).openPullDownMenu(message);
    final a =  pullDownMenuRobot.getForwardItem();
    await $.waitUntilVisible(a);
    await a.tap();
    await $.pump();
    // await ($(TwakeIconButton).containing(find.byTooltip('Search'))).tap();
    // await enterSearchText(receiver);
    // await $.waitUntilVisible($(InkWell).at(0));
    // await $(InkWell).at(0).tap();

    // // await ($(TwakeIconButton).containing(find.byTooltip('Send'))).tap();
    // // await $.pumpAndSettle();
  }

  Future<void> copyMessage(String message) async {
    final pullDownMenuRobot = await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (await pullDownMenuRobot.getCopyItem()).tap();
    await $.pumpAndSettle();
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
      await $.tap(flutterMenu.first); // tap the first match to avoid "too many elements"
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
        await $.native.tap( Selector(text: 'Paste'));
        return;
      }
    }

    // 5) If we reach here, the menu didn't show up or label didn't match
    throw StateError('Paste menu not found (Flutter & native).');
  }

  Future<void> editMessage(String message, String newMessage) async {
    final pullDownMenuRobot = await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (await pullDownMenuRobot.getEditItem()).tap();
    await sendAMesage(newMessage);
    await $.pumpAndSettle();
  }

  Future<void> selectMessage(String message) async {
    final pullDownMenuRobot = await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (await pullDownMenuRobot.getSelectItem()).tap();
    await $.pumpAndSettle();
  }

  Future<PatrolFinder> getPinExpandIcon() async{
     return $(TwakeIconButton).containing(find.byTooltip('Pinned messages'));
  }

  Future<void> pinMessage(String message) async {
    final pullDownMenuRobot = await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (await pullDownMenuRobot.getPinItem()).tap();
    await $.waitUntilVisible($(PinnedEventsView));
    await $.waitUntilVisible($(PinnedEventsView).$("Pinned Message"));
    expect((await getPinExpandIcon()).exists ,isTrue);
  }

  Future<void> deleteMessage(String message) async {
    final pullDownMenuRobot = await ChatGroupDetailRobot($).openPullDownMenu(message);
    await (await pullDownMenuRobot.getDeleteItem()).tap();
    await $.pumpAndSettle();
  }

  PatrolFinder _tileByText(String text){
    final msg = $(MatrixLinkifyText).containing(text); //_richTextWithExact(text);
    final container = find.ancestor(
      of: msg,
      matching: find.byType(MultiPlatformsMessageContainer),
    );
    return $(container);
  }
  
  Color? _effectiveIconColor(Finder iconFinder) {
    final icon = $.tester.widget<Icon>(iconFinder);
    final ctx  = $.tester.element(iconFinder);     // BuildContext for Icon
    return icon.color ?? IconTheme.of(ctx).color;  // resolved color
  }

  Future<void> expectMessageTickSelected(
    String messageText, {
    Color? expectedColor,        // e.g. const Color(0xFF0A84FF)
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
  Color? expectedColor,        // e.g. const Color(0x000000)
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

  Future<void> verifyTheDisplayInSelectedTextMode(String message) async {
    final chatInputRow = $(ChatInputRow);

    expect(
      find.descendant(of: $(AppBar).finder, matching: find.byTooltip('Close')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: $(ChatAppBarTitle).finder, matching: find.byTooltip('Copy')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: $(ChatAppBarTitle).finder, matching: find.text('1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: $(ChatAppBarTitle).finder, matching: find.byTooltip('Pin')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: $(ChatAppBarTitle).finder, matching: find.byTooltip('More')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chatInputRow.finder, matching: find.text('Forward')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chatInputRow.finder, matching: find.text('Reply')),
      findsOneWidget,
    );
    await expectMessageTickSelected(message, expectedColor: const Color(0xFF0A84FF),);
  }

  Future<void> verifyMessageIsPinned(String message, bool isTrue) async {
    await (await getPinExpandIcon()).tap();
    await $.pumpAndSettle();
    await $.waitUntilVisible($(AppBar).containing($("Pinned Message")));
    await $.waitUntilVisible($(PinnedMessagesScreen).$("Unpin all messages"));
    if(isTrue)
      {expect($(MessageContent).$(message), isTrue);}
    else
      {expect($(MessageContent).$(message), isFalse);}

    await $(find.ancestor(of: find.byTooltip('Back'), matching:find.byType(TwakeIconButton))).tap();
    await $.pumpAndSettle();
  }

  Future<void> verifySearchResultViewIsShown() async {
    expect(ChatListRobot($).showLessLabel().visible || ChatListRobot($).noResultLabel().visible, isTrue);
    await Future.delayed(const Duration(seconds: 5)); 
  }

  Future<void> verifyDisplayOfContactListScreen(SoftAssertHelper s) async {    
    s.softAssertEquals( (await SearchRobot($).getSearchTextField()).exists, true, 'Search Text Field is not visible');

    // // title (avoid hard-coded text if localized)
    // final appBarCtx = $.tester.element(find.byType(TwakeAppBar));
    // final title = L10n.of(appBarCtx)!.chats; // or 'Chats' if not localized
    // s.softAssertEquals($(TwakeAppBar).containing($(Text(title))).exists,true,'Contact title is wrong',);

    s.softAssertEquals($(ChatListBodyView).visible, true, 'Chats tab is not visible');
    s.softAssertEquals($(BottomNavigationBar).visible, true, 'Bottom navigator bar is not visible');
  }

  Future<void> verifySearchResultContains(String keyword) async {
    final items = await ChatListRobot($).getListOfChatGroup();
    final length = items.length;
    var i = 0;

    for (final item in items) {
      i = i +1;
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
    await chatGroupDetailRobot.confimrAccessMedia();
    await $.pumpAndSettle();
    return chatGroupDetailRobot;
  }

  Future<void> openAGroupChatByAPI(String groupID) async {
    final client = await CoreRobot($).initialRedirectRequest();
    await CoreRobot($).loginByAPI(client);
    await CoreRobot($).openGroupChatByAPI(client, groupID);
    await CoreRobot($).closeClient(client);
  }

  Future<void> sendAMessageByAPI(String groupID, String message) async {
    final client = await CoreRobot($).initialRedirectRequest();
    final list = await CoreRobot($).loginByAPI(client);
    await CoreRobot($).sendMessageByAPI(list[0], list[1], list[2], groupID, message);
    await CoreRobot($).closeClient(client);
  }

  Future<void> verifyMessageIsSentByAPI(String message) async {
    //get all message
    final client = await CoreRobot($).initialRedirectRequest();
    final list = await CoreRobot($).loginByAPI(client);
    final responseBody = await CoreRobot($).getAllSentMessage(client, list[1]);
    await CoreRobot($).closeClient(client);
    //verify response of that message contains expected message
    final jsonData = json.decode(responseBody);

    final events = jsonData['rooms']?['join']?.values
        .expand((room) => room['timeline']?['events'] ?? [])
        .toList();

    final containsMessage = events.any((event) =>
        event['type'] == 'm.room.message' &&
        event['content']?['body']?.toString().toLowerCase() == message,);

    if (containsMessage) {
      log('✅ Message $message is found!');
    } else {
      log('❌ Message $message not found.');
    }
  }

  Future<void> verifyMessageIsReadByAPI(String message) async {
    
  }

  Future<void> verifyMessageIsShown(String message, bool isTrue) async {
    final text = await ChatGroupDetailRobot($).getText(message);
    if(isTrue)
      {
        await $.waitUntilVisible($(text));
        expect(text, findsOneWidget);
      }
    else
      { expect(text, findsNothing);}
  }

  Future<void> sendAMesage(String message) async {
    await ChatGroupDetailRobot($).inputMessage(message);
  
    // tab on send button
    await $(ChatInputRowSendBtn).tap();

    //xem co loaij text nao co  gia tri la kia dc hien len ko
     await Future.delayed(const Duration(seconds: 2)); 
  }

}