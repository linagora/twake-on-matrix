import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat/input_bar/focus_suggestion_list.dart';
import 'package:twake_chat/pages/chat/input_bar/input_bar.dart';
import 'package:twake_chat/pages/chat/input_bar/input_bar_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_search/chat_search_view.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;
import 'package:twake_chat/widgets/twake_components/twake_loading/center_loading_indicator.dart';

import '../base/base_test_scenario.dart';
import '../base/mobile_group_fixture.dart';
import '../robots/chat_group_detail_robot.dart';

int _uid() => DateTime.now().microsecondsSinceEpoch;

/// Swipe a message to quote it in the composer, then send the reply.
class SwipeToReplyScenario extends BaseTestScenario {
  SwipeToReplyScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await openMobileGroupFixture(this);
    final chat = ChatGroupDetailRobot($);
    final original = 'swipe original ${_uid()}';
    final reply = 'swipe reply ${_uid()}';

    await chat.sendMessage(original);
    await chat.swipeToReply(original);
    await chat.sendMessage(reply);

    await chat.expectReplyTo(reply: reply, original: original);
    await chat.waitUntilAbsent($, chat.composerReplyPreview(original));
  }
}

/// Typing `@` lists every other member of the room; a prefix narrows the
/// list and picking a member inserts the mention.
class MentionSuggestionsScenario extends BaseTestScenario {
  MentionSuggestionsScenario(super.$, super.robots);

  static const _groupId = String.fromEnvironment('GroupID');

  @override
  Future<void> runTestLogic() async {
    final (room, others) = await _groupWithMembers();
    await robots.chatListRobot().openSearchScreen();
    final opened = await robots.searchViewRobot().searchAndOpenRoom(
      room.getLocalizedDisplayname(),
    );
    if (!opened) {
      throw Exception('Room "${room.getLocalizedDisplayname()}" not found.');
    }

    final chat = ChatGroupDetailRobot($);
    await chat.scrollToLiveBottom();
    final field = await chat.getInputTextField();
    TextField composer() => $.tester.widget<TextField>(field);
    await field.tap();
    // Patrol unfocuses the field after typing by default, which closes the
    // suggestions.
    await field.enterText('@', hideKeyboard: false);
    final list = $(FocusSuggestionList);
    await $.waitUntilVisible(list, timeout: const Duration(seconds: 15));

    expect(
      $.tester.widget<FocusSuggestionList>(list).items.length,
      others.length,
      reason: 'The suggestion list must hold every other member.',
    );
    final scrollable = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    for (final member in others) {
      await $.tester.scrollUntilVisible(
        _suggestion(member.id),
        InputBarStyle.suggestionSize,
        scrollable: scrollable,
      );
    }

    final picked = others.last;
    final prefix = '@${picked.id.substring(1).split(':').first}';
    await field.enterText(prefix, hideKeyboard: false);
    await $.waitUntilExists(
      $(_suggestion(picked.id)),
      timeout: const Duration(seconds: 15),
    );
    for (final member in others.where((m) => m.id != picked.id)) {
      await chat.waitUntilAbsent($, $(_suggestion(member.id)));
    }

    await $.tester.tap(_suggestion(picked.id));
    await $.pumpAndTrySettle();
    expect(composer().controller!.text.trim(), picked.mention);

    await field.enterText('');
  }

  Finder _suggestion(String matrixId) => find.ancestor(
    of: find.text(matrixId),
    matching: find.byType(SuggestionTile),
  );

  /// The provisioned group, which holds at least two members besides us.
  Future<(Room, List<User>)> _groupWithMembers() async {
    if (_groupId.isEmpty) {
      throw StateError('Missing required --dart-define=GroupID');
    }
    await $(ChatList).waitUntilVisible(timeout: const Duration(seconds: 60));
    final context = $.tester.element(find.byType(Scaffold).first);
    final client = twake.Matrix.of(context).client;
    await client.roomsLoading;

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    var room = client.getRoomById(_groupId);
    while (room == null && DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 500));
      room = client.getRoomById(_groupId);
    }
    if (room == null) throw StateError('Room $_groupId is not loaded.');

    final others =
        (await room.requestParticipants([
            Membership.join,
          ])).where((member) => member.id != client.userID).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (others.length < 2) {
      throw StateError('Room $_groupId needs two members besides us.');
    }
    return (room, others);
  }
}

/// Searching a word inside a chat lists every message containing it, and
/// only those.
class SearchAllRelatedMessagesScenario extends BaseTestScenario {
  SearchAllRelatedMessagesScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await openMobileGroupFixture(this);
    final chat = ChatGroupDetailRobot($);
    final keyword = 'needle${_uid()}';
    final related = ['$keyword alpha', '$keyword beta', '$keyword gamma'];
    final unrelated = 'haystack ${_uid()} delta';

    for (final message in [...related, unrelated]) {
      await chat.sendMessage(message);
      await $.waitUntilExists(
        await chat.getText(message),
        timeout: const Duration(seconds: 60),
      );
    }

    await chat.getSearchIcon().first.tap();
    final searchView = $(ChatSearchView);
    await $.waitUntilVisible(searchView);
    await chat.typeSlowlyWithPatrol($, searchView.$(TextField), keyword);

    final results = searchView.$(TwakeListItem);
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (results.evaluate().length < related.length &&
        DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 500));
    }
    await chat.waitUntilAbsent(
      $,
      searchView.$(CenterLoadingIndicator),
      timeout: const Duration(seconds: 30),
    );

    expect(results.evaluate().length, related.length);
    for (final message in related) {
      expect(
        results.containing(find.textContaining(message, findRichText: true)),
        findsOneWidget,
      );
    }
    expect(
      searchView.$(find.textContaining('delta', findRichText: true)),
      findsNothing,
    );
  }
}
