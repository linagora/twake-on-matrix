import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/personalization/chat_list_search_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_view.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_pills.dart';
import 'package:twake_chat/pages/chat_list/slidable_chat_list_item.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/floating_navigation_bar.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';

import 'chat_list_header_test_harness.dart';

// The « collapsing » search style (Clément, 2026-11-26): a thin search field
// at the top of the phone header that folds away once the list scrolls; the
// round search button of the bar shows only then.

// `NavigationKeys.collapsingSearchField`, `.searchButton`, `.searchField`,
// `.searchCloseButton`.
const _topField = Key('navigation.collapsingSearchField');
const _searchButton = Key('navigation.searchButton');
const _searchField = Key('navigation.searchField');
const _closeButton = Key('navigation.searchCloseButton');

/// Stands for the results of `pages/search`, which the chat list is given.
const _results = Key('search_results');

final _rooms = find.byType(SlidableChatListItem);
final _pills = find.byType(RoomListFilterPills);
final _title = find.descendant(of: headerFinder, matching: find.text('Chats'));

/// The Chats tab of a phone as the app builds it, in [style]: the chat list
/// over the floating bar, both on the same search.
Future<HeaderHarness> _pumpChats(
  WidgetTester tester, {
  ChatListSearchStyle style = ChatListSearchStyle.collapsing,
  HeaderView view = const HeaderView.phone(),
}) {
  final open = ValueNotifier(false);
  final query = TextEditingController();
  addTearDown(open.dispose);
  addTearDown(query.dispose);
  return HeaderHarness.pump(
    tester,
    view,
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

bool _barFieldFocused(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(_searchField),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode
    .hasFocus;

void main() {
  setUpHeaderTests();
  _atTheTop();
  _scrolled();
  _partlyScrolled();
  _fromTheTopField();
  _assistiveTechnology();
  _otherStylesAndLayouts();
}

void _atTheTop() {
  group('[ChatList] collapsing search, at the top of the list', () {
    testWidgets('GIVEN the top of the list\n'
        'THEN a thin search field shows in the header, 40 high', (
      tester,
    ) async {
      await _pumpChats(tester);

      final field = find.descendant(
        of: headerFinder,
        matching: find.byKey(_topField),
      );
      expect(field.hitTestable(), findsOneWidget);
      expect(tester.getSize(field).height, 40);
    });

    testWidgets('GIVEN the top of the list\n'
        'THEN the search field sits above the folder pills', (tester) async {
      await _pumpChats(tester);

      expect(
        tester.getRect(find.byKey(_topField)).bottom,
        lessThanOrEqualTo(tester.getRect(_pills).top),
      );
    });

    testWidgets('GIVEN the top of the list\n'
        'THEN the search field is announced as « Search »', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpChats(tester);

      expect(
        find.descendant(
          of: find.byKey(_topField),
          matching: find.bySemanticsLabel(RegExp('Search')),
          matchRoot: true,
        ),
        findsWidgets,
      );
      semantics.dispose();
    });

    testWidgets('GIVEN the top of the list\n'
        'THEN the bar has no search button', (tester) async {
      await _pumpChats(tester);

      expect(find.byKey(_searchButton).hitTestable(), findsNothing);
      expect(_rooms, findsWidgets);
    });
  });
}

void _scrolled() {
  group('[ChatList] collapsing search, once the list scrolls', () {
    _scrolledHeader();
    _scrolledSearchButton();
  });
}

void _scrolledHeader() {
  testWidgets('GIVEN the list is scrolled down\n'
      'THEN the search field has folded away', (tester) async {
    await _pumpChats(tester);
    expect(find.byKey(_topField).hitTestable(), findsOneWidget);

    await scrollDown(tester, 400);

    expect(find.byKey(_topField).hitTestable(), findsNothing);
  });

  testWidgets('GIVEN the list is scrolled down\n'
      'THEN the title and the folder pills stay pinned at the top', (
    tester,
  ) async {
    final h = await _pumpChats(tester);

    await scrollDown(tester, 400);

    expect(h.scroll.offset, greaterThan(0));
    expect(headerVisible(tester), isTrue);
    expect(tester.getTopLeft(headerFinder).dy, 0);
    expect(_title.hitTestable(), findsOneWidget);
    expect(_pills.hitTestable(), findsOneWidget);
  });

  testWidgets('GIVEN the list is scrolled down\n'
      'THEN the header shows no search control', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpChats(tester);
    final searchInHeader = find.descendant(
      of: headerFinder,
      matching: find.bySemanticsLabel(RegExp('Search')),
    );
    expect(searchInHeader, findsWidgets, reason: 'the top field');

    await scrollDown(tester, 400);

    expect(headerVisible(tester), isTrue);
    expect(searchInHeader, findsNothing);
    semantics.dispose();
  });
}

void _scrolledSearchButton() {
  testWidgets('GIVEN the list is scrolled down\n'
      'THEN the round search button shows at the end of the bar', (
    tester,
  ) async {
    await _pumpChats(tester);
    expect(find.byKey(_searchButton).hitTestable(), findsNothing);

    await scrollDown(tester, 400);

    expect(find.byKey(_searchButton).hitTestable(), findsOneWidget);
  });

  testWidgets('GIVEN the list is scrolled down\n'
      'WHEN the search button is tapped\n'
      'THEN the bar field opens focused and the results replace the rows', (
    tester,
  ) async {
    await _pumpChats(tester);
    await scrollDown(tester, 400);

    await tester.tap(find.byKey(_searchButton));
    await tester.pumpAndSettle();

    expect(_barFieldFocused(tester), isTrue);
    expect(find.byKey(_results).hitTestable(), findsOneWidget);
    expect(_rooms, findsNothing);

    await tester.enterText(find.byKey(_searchField), 'taisiya');
    await tester.pumpAndSettle();
    expect(find.text('results for « taisiya »'), findsOneWidget);
  });

  testWidgets('GIVEN the search was opened from the bar\n'
      'WHEN the close button is tapped\n'
      'THEN the chat list is back', (tester) async {
    await _pumpChats(tester);
    await scrollDown(tester, 400);
    await tester.tap(find.byKey(_searchButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_closeButton));
    await tester.pumpAndSettle();

    expect(_rooms, findsWidgets);
    expect(find.byKey(_results), findsNothing);
  });

  testWidgets('GIVEN the list was scrolled down\n'
      'WHEN it goes back to the very top\n'
      'THEN the search field is back and the search button gone', (
    tester,
  ) async {
    final h = await _pumpChats(tester);
    await scrollDown(tester, 400);

    h.scroll.jumpTo(0);
    await tester.pumpAndSettle();

    expect(find.byKey(_topField).hitTestable(), findsOneWidget);
    expect(find.byKey(_searchButton).hitTestable(), findsNothing);
  });
}

void _fromTheTopField() {
  group('[ChatList] collapsing search, from the top field', () {
    testWidgets('GIVEN the top of the list\n'
        'WHEN the thin search field is tapped\n'
        'THEN the bar field opens focused, keyboard up, with the results', (
      tester,
    ) async {
      await _pumpChats(tester);

      await tester.tap(find.byKey(_topField));
      await tester.pumpAndSettle();

      expect(find.byKey(_searchField).hitTestable(), findsOneWidget);
      expect(_barFieldFocused(tester), isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(find.byKey(_results).hitTestable(), findsOneWidget);
      expect(_rooms, findsNothing);
    });

    testWidgets('GIVEN the search was opened from the top field\n'
        'WHEN the user types\n'
        'THEN the same results follow, in place, not on another page', (
      tester,
    ) async {
      await _pumpChats(tester);
      await tester.tap(find.byKey(_topField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(_searchField), 'taisiya');
      await tester.pumpAndSettle();

      expect(find.text('results for « taisiya »'), findsOneWidget);
      expect(find.byType(ChatListView).hitTestable(), findsOneWidget);
    });

    testWidgets('GIVEN the search was opened from the top field\n'
        'WHEN Android back is pressed\n'
        'THEN the list is back at the top with its search field', (
      tester,
    ) async {
      await _pumpChats(tester);
      await tester.tap(find.byKey(_topField));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_rooms, findsWidgets);
      expect(find.byKey(_results), findsNothing);
      expect(find.byKey(_topField).hitTestable(), findsOneWidget);
      expect(find.byKey(_searchButton).hitTestable(), findsNothing);
    });
  });
}

void _otherStylesAndLayouts() {
  group('[ChatList] search styles', () {
    testWidgets('GIVEN the default style (bottom bar)\n'
        'THEN the header has no search field and the button always shows', (
      tester,
    ) async {
      await _pumpChats(tester, style: ChatListSearchStyle.bottomBar);

      expect(find.byKey(_topField), findsNothing);
      expect(find.byKey(_searchButton).hitTestable(), findsOneWidget);
    });

    testWidgets('GIVEN the default style\n'
        'THEN it is the bottom bar one', (tester) async {
      await HeaderHarness.pump(tester, const HeaderView.phone());

      expect(find.byKey(_topField), findsNothing);
    });

    testWidgets('GIVEN a wide screen in the collapsing style\n'
        'THEN the header keeps its own search, no thin field', (tester) async {
      await HeaderHarness.pump(
        tester,
        const HeaderView.wide(),
        buildView: (controller) => ChatListView(
          controller: controller,
          onTapBottomNavigation: (_) {},
          searchStyle: ChatListSearchStyle.collapsing,
        ),
      );

      expect(find.byKey(_topField), findsNothing);
      expect(
        find.descendant(of: headerFinder, matching: find.byType(TextField)),
        findsOneWidget,
      );
    });
  });
}

void _assistiveTechnology() {
  group('[ChatList] collapsing search, with a screen reader', () {
    testWidgets('GIVEN the top of the list\n'
        'WHEN the screen reader activates the « Search » field\n'
        'THEN the search opens', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpChats(tester);
      final field = find.semantics.byLabel('Search');
      expect(
        field,
        containsSemantics(isButton: true, hasTapAction: true),
        reason: 'a button a screen reader cannot activate opens nothing',
      );

      tester.semantics.tap(field);
      await tester.pumpAndSettle();

      expect(_barFieldFocused(tester), isTrue);
      expect(find.byKey(_results).hitTestable(), findsOneWidget);
      semantics.dispose();
    });
  });
}

Future<void> _scrollTo(
  WidgetTester tester,
  HeaderHarness h,
  double offset,
) async {
  h.scroll.jumpTo(offset);
  await tester.pumpAndSettle();
  expect(h.scroll.offset, offset);
}

// The round button takes over from the top field, never beside it: it shows
// once the list has scrolled the whole field away.
void _partlyScrolled() {
  final extent = ChatListHeaderStyle.collapsingSearchExtent;
  group('[ChatList] collapsing search, the top field partly scrolled', () {
    for (final (name, offset) in [
      ('by one pixel', 1.0),
      ('halfway', extent / 2),
      ('all but one pixel', extent - 1),
    ]) {
      testWidgets('GIVEN the field is scrolled $name\n'
          'THEN the bar has no search button yet', (tester) async {
        final h = await _pumpChats(tester);

        await _scrollTo(tester, h, offset);

        expect(find.byKey(_topField), findsOneWidget);
        expect(find.byKey(_searchButton).hitTestable(), findsNothing);
      });
    }

    testWidgets('GIVEN the field is scrolled away, no further\n'
        'THEN the search button of the bar shows', (tester) async {
      final h = await _pumpChats(tester);

      await _scrollTo(tester, h, extent);

      expect(find.byKey(_topField).hitTestable(), findsNothing);
      expect(find.byKey(_searchButton).hitTestable(), findsOneWidget);
    });

    testWidgets('GIVEN the search button shows\n'
        'WHEN the field comes partly back\n'
        'THEN the button goes', (tester) async {
      final h = await _pumpChats(tester);
      await _scrollTo(tester, h, 400);
      expect(find.byKey(_searchButton).hitTestable(), findsOneWidget);

      await _scrollTo(tester, h, extent / 2);

      expect(find.byKey(_searchButton).hitTestable(), findsNothing);
    });
  });
}
