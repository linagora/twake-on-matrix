import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/personalization/chat_list_search_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_bottom_navigator.dart';
import 'package:twake_chat/pages/chat_list/chat_list_view.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_pills.dart';
import 'package:twake_chat/pages/chat_list/slidable_chat_list_item.dart';
import 'package:twake_chat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/floating_navigation_bar.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';

import 'chat_list_header_test_harness.dart';

// `NavigationKeys.searchButton`, `.searchField` and `.searchCloseButton`.
const _searchButton = Key('navigation.searchButton');
const _searchField = Key('navigation.searchField');
const _closeButton = Key('navigation.searchCloseButton');

/// Stands for the results of `pages/search`, which the chat list is given.
const _results = Key('search_results');

final _rooms = find.byType(SlidableChatListItem);
final _pills = find.byType(RoomListFilterPills);
final _title = find.descendant(of: headerFinder, matching: find.text('Chats'));

/// The Chats tab of a phone as the app builds it: the chat list over the
/// floating bar, both on the same search.
Future<HeaderHarness> _pumpChats(
  WidgetTester tester, {
  ChatListSearchStyle style = ChatListSearchStyle.bottomBar,
  ValueNotifier<bool>? searchOpen,
}) {
  final open = searchOpen ?? ValueNotifier(false);
  final query = TextEditingController();
  if (searchOpen == null) addTearDown(open.dispose);
  addTearDown(query.dispose);
  return HeaderHarness.pump(
    tester,
    const HeaderView.phone(),
    buildView: (controller) => ChatListView(
      controller: controller,
      onTapBottomNavigation: (_) {},
      searchStyle: style,
      searchOpen: open,
      searchResults: ValueListenableBuilder(
        key: _results,
        valueListenable: query,
        builder: (_, value, _) => Text('results for « ${value.text} »'),
      ),
      bottomNavigationBar: FloatingNavigationBar(
        destinations: AdaptiveDestinationEnum.values,
        selected: AdaptiveDestinationEnum.rooms,
        onDestinationSelected: (_) {},
        searchOpen: open,
        searchQuery: query,
      ),
    ),
  );
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.byKey(_searchButton));
  await tester.pumpAndSettle();
}

void main() {
  setUpHeaderTests();

  group('[ChatList] search from the bottom bar', () {
    testWidgets('GIVEN a phone\n'
        'THEN the chat list shows, not the search results', (tester) async {
      await _pumpChats(tester);

      expect(_rooms, findsWidgets);
      expect(find.byKey(_results), findsNothing);
    });

    testWidgets('GIVEN a phone\n'
        'WHEN the search button of the bar is tapped\n'
        'THEN the search results show in place of the chat list', (
      tester,
    ) async {
      await _pumpChats(tester);

      await _openSearch(tester);

      expect(find.byKey(_results).hitTestable(), findsOneWidget);
      expect(_rooms, findsNothing);
    });

    testWidgets('GIVEN the search is open\n'
        'THEN the field of the bar is the only search field of the screen', (
      tester,
    ) async {
      await _pumpChats(tester);

      await _openSearch(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(_searchField), findsOneWidget);
    });

    testWidgets('GIVEN the search is open\n'
        'WHEN the user types in the field of the bar\n'
        'THEN the results follow what is typed', (tester) async {
      await _pumpChats(tester);
      await _openSearch(tester);

      await tester.enterText(find.byKey(_searchField), 'taisiya');
      await tester.pumpAndSettle();

      expect(find.text('results for « taisiya »'), findsOneWidget);
    });

    testWidgets('GIVEN the search is open\n'
        'WHEN the keyboard is up\n'
        'THEN the field stays above it', (tester) async {
      await _pumpChats(tester);
      await _openSearch(tester);

      const keyboard = 300.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(_searchField)).bottom,
        lessThan(mobileSize.height - keyboard),
      );
    });

    testWidgets('GIVEN the search is open\n'
        'WHEN the close button is tapped\n'
        'THEN the chat list is back', (tester) async {
      await _pumpChats(tester);
      await _openSearch(tester);

      await tester.tap(find.byKey(_closeButton));
      await tester.pumpAndSettle();

      expect(_rooms, findsWidgets);
      expect(find.byKey(_results), findsNothing);
    });

    testWidgets('GIVEN the search is open\n'
        'WHEN Android back is pressed\n'
        'THEN the chat list is back', (tester) async {
      await _pumpChats(tester);
      await _openSearch(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_rooms, findsWidgets);
      expect(find.byKey(_results), findsNothing);
      expect(find.byKey(_searchButton), findsOneWidget);
    });
  });

  // Clément, 2026-11-26: the search screen has no folders; the app bar stays.
  for (final style in ChatListSearchStyle.values) {
    group('[ChatList] folder pills and the search (${style.name})', () {
      testWidgets('GIVEN the search is closed\n'
          'THEN the folder pills show', (tester) async {
        await _pumpChats(tester, style: style);

        expect(_pills, findsOneWidget);
      });

      testWidgets('GIVEN the search is open\n'
          'THEN the folder pills do not show', (tester) async {
        final open = ValueNotifier(false);
        addTearDown(open.dispose);
        await _pumpChats(tester, style: style, searchOpen: open);

        open.value = true;
        await tester.pumpAndSettle();

        expect(find.byKey(_results).hitTestable(), findsOneWidget);
        expect(_pills, findsNothing);
      });

      testWidgets('GIVEN the search is open\n'
          'THEN the app bar and its title stay', (tester) async {
        final open = ValueNotifier(false);
        addTearDown(open.dispose);
        await _pumpChats(tester, style: style, searchOpen: open);

        open.value = true;
        await tester.pumpAndSettle();

        expect(_title.hitTestable(), findsOneWidget);
      });

      testWidgets('GIVEN the search is open\n'
          'WHEN it closes\n'
          'THEN the folder pills come back', (tester) async {
        final open = ValueNotifier(false);
        addTearDown(open.dispose);
        await _pumpChats(tester, style: style, searchOpen: open);
        open.value = true;
        await tester.pumpAndSettle();

        open.value = false;
        await tester.pumpAndSettle();

        expect(_pills.hitTestable(), findsOneWidget);
      });
    });
  }

  group('[ChatList] select mode over the bottom bar', () {
    testWidgets('GIVEN conversations are ticked\n'
        'THEN the selection actions replace the tabs and the search button', (
      tester,
    ) async {
      final h = await _pumpChats(tester);

      h.controller.conversationSelectionNotifier.value = const [
        ConversationSelectionPresentation(
          roomId: '!room0:fakeServer',
          selectionType: SelectionType.selected,
        ),
      ];
      await tester.pumpAndSettle();

      expect(find.byType(ChatListBottomNavigator), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsNothing);
      expect(find.byKey(_searchButton), findsNothing);
    });

    testWidgets('GIVEN the selection is emptied\n'
        'THEN the tabs and the search button come back', (tester) async {
      final h = await _pumpChats(tester);
      h.controller.conversationSelectionNotifier.value = const [
        ConversationSelectionPresentation(
          roomId: '!room0:fakeServer',
          selectionType: SelectionType.selected,
        ),
      ];
      await tester.pumpAndSettle();

      h.controller.conversationSelectionNotifier.value = const [];
      await tester.pumpAndSettle();

      expect(find.byType(ChatListBottomNavigator), findsNothing);
      expect(find.byKey(_searchButton).hitTestable(), findsOneWidget);
    });
  });
}
