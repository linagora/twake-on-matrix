import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';

import 'chat_list_header_test_harness.dart';

void main() {
  setUpHeaderTests();
  _oneColumn();
  _multiColumn();
}

void _oneColumn() {
  group('[ChatList] collapsing header on a one column layout', () {
    _showsAtTop();
    _hidesOnScrollDown();
    _comesBackOnScrollUp();
    _returnsToFullHeightAtTop();
    _selectMode();
    _controllerListener();
    _noRoom();
  });
}

void _showsAtTop() {
  testWidgets('GIVEN the top of the list\n'
      'THEN the header is shown above the first room', (tester) async {
    final h = await HeaderHarness.pump(tester, const HeaderView.phone());
    expect(headerVisible(tester), isTrue);
    expect(h.scroll.offset, 0);
    expect(find.byType(ChatListHeader), findsOneWidget);
  });
}

void _hidesOnScrollDown() {
  testWidgets('GIVEN the list is scrolled down by more than the header\n'
      'THEN the header is hidden', (tester) async {
    final h = await HeaderHarness.pump(tester, const HeaderView.phone());

    await scrollDown(tester, 400);

    expect(h.scroll.offset, greaterThan(0));
    expect(headerVisible(tester), isFalse);
  });
}

void _comesBackOnScrollUp() {
  testWidgets('GIVEN the header is hidden\n'
      'WHEN the user scrolls back up a little\n'
      'THEN the header comes back and ends fully visible', (tester) async {
    await HeaderHarness.pump(tester, const HeaderView.phone());
    final atTop = tester.getRect(headerFinder);
    await scrollDown(tester, 400);
    expect(headerVisible(tester), isFalse);

    await scrollUp(tester, 60);

    // Fully back: where it sits at the top of the list, whatever its height.
    expect(headerVisible(tester), isTrue);
    expect(tester.getTopLeft(headerFinder).dy, moreOrLessEquals(atTop.top));
    expect(tester.getRect(headerFinder).bottom, moreOrLessEquals(atTop.bottom));
  });
}

void _returnsToFullHeightAtTop() {
  testWidgets('GIVEN the user scrolls back to the very top\n'
      'THEN the header is shown at its full height', (tester) async {
    final h = await HeaderHarness.pump(tester, const HeaderView.phone());
    final fullHeight = tester.getSize(headerFinder).height;
    await scrollDown(tester, 400);

    h.scroll.jumpTo(0);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(headerFinder).dy, 0);
    expect(tester.getSize(headerFinder).height, fullHeight);
  });
}

void _selectMode() {
  testWidgets('GIVEN select mode\n'
      'THEN scrolling down never hides the header', (tester) async {
    final h = await HeaderHarness.pump(tester, const HeaderView.phone());
    h.controller.selectModeNotifier.value = SelectMode.select;
    await tester.pump();

    await scrollDown(tester, 400);

    expect(h.scroll.offset, greaterThan(0));
    expect(headerVisible(tester), isTrue);
  });

  testWidgets('GIVEN the header is hidden\n'
      'WHEN select mode starts\n'
      'THEN the header is shown again', (tester) async {
    final h = await HeaderHarness.pump(tester, const HeaderView.phone());
    await scrollDown(tester, 400);
    expect(headerVisible(tester), isFalse);

    await h.startSelectMode(tester);

    expect(headerVisible(tester), isTrue);
  });
}

void _controllerListener() {
  testWidgets('GIVEN the controller scrolls the list itself\n'
      'THEN the scroll listener of the controller still fires', (tester) async {
    final h = await HeaderHarness.pump(tester, const HeaderView.phone());
    var calls = 0;
    var lastWasTop = true;
    h.scroll.addListener(() {
      calls++;
      lastWasTop = h.scroll.position.pixels <= 0;
    });

    await scrollDown(tester, 400);
    expect(lastWasTop, isFalse);
    h.scroll.jumpTo(0);
    await tester.pumpAndSettle();

    expect(calls, greaterThan(0));
    expect(lastWasTop, isTrue);
  });
}

void _noRoom() {
  testWidgets('GIVEN no room yet\n'
      'THEN the header is shown at the top, without scrolling', (tester) async {
    await HeaderHarness.pump(tester, const HeaderView.phone(roomCount: 0));

    expect(headerVisible(tester), isTrue);
    expect(find.byType(CustomScrollView), findsNothing);
    expect(tester.getTopLeft(headerFinder).dy, 0);
  });
}

void _multiColumn() {
  group('[ChatList] header on a multi column layout', () {
    testWidgets('GIVEN a wide screen\n'
        'THEN the header stays in the app bar and never hides', (tester) async {
      final h = await HeaderHarness.pump(tester, const HeaderView.wide());
      expect(headerVisible(tester), isTrue);
      expect(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: headerFinder,
        ),
        findsNothing,
        reason: 'wide layouts keep the header outside the scrolling list',
      );

      await scrollDown(tester, 400);

      expect(h.scroll.offset, greaterThan(0));
      expect(headerVisible(tester), isTrue);
    });
  });
}
