import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_pills.dart';

import 'chat_list_header_test_harness.dart';

void main() {
  setUpHeaderTests();
  _blockWithInset();
  _backgroundColour();
  _statusBarBand();
}

/// A phone with a status bar, one of the three views.
Future<HeaderHarness> _pumpPhone(WidgetTester tester, {HeaderView? branch}) =>
    HeaderHarness.pump(tester, branch ?? const HeaderView.phoneWithStatusBar());

/// Scrolls down, then back up a little: the header comes back.
Future<void> _scrollAwayAndBack(WidgetTester tester, double away) async {
  await scrollDown(tester, away);
  await scrollUp(tester, 80);
}

void _blockWithInset() {
  group('[ChatList] header block with a status bar inset', () {
    for (final entry in headerBranches.entries) {
      _insetCases(entry.key, entry.value);
    }
    _wideScreenBlock();
    _filterBarKeepsState();
    _hiddenAboveScreen();
  });
}

void _insetCases(String name, HeaderView branch) {
  testWidgets('GIVEN $name on a phone with a status bar\n'
      'THEN nothing overflows', (tester) async {
    await _pumpPhone(tester, branch: branch);

    expect(tester.takeException(), isNull);
  });

  testWidgets('GIVEN $name on a phone with a status bar\n'
      'THEN the chips sit inside the header, inside its reserved box', (
    tester,
  ) async {
    await _pumpPhone(tester, branch: branch);
    tester.takeException();

    final header = tester.getRect(headerFinder);
    final chips = tester.getRect(find.byType(RoomListFilterPills));
    final reserved = tester.getRect(reservedBox);
    expect(chips.top, greaterThanOrEqualTo(header.top - 0.01));
    expect(chips.bottom, lessThanOrEqualTo(header.bottom + 0.01));
    expect(header.bottom, lessThanOrEqualTo(reserved.bottom + 0.01));
  });

  testWidgets('GIVEN $name on a phone with a status bar\n'
      'THEN the block is as high as its preferred height plus the status bar', (
    tester,
  ) async {
    await _pumpPhone(tester, branch: branch);
    tester.takeException();

    expect(tester.getSize(reservedBox).height, headerBlockHeight);
    expect(tester.getSize(headerFinder).height, headerBlockHeight);
  });
}

void _wideScreenBlock() {
  testWidgets('GIVEN a wide screen with the same status bar\n'
      'THEN its appBar block is its preferred height plus the status bar', (
    tester,
  ) async {
    await HeaderHarness.pump(
      tester,
      const HeaderView.wide(topInset: statusBar),
    );

    expect(tester.getSize(headerFinder).height, wideHeaderBlockHeight);
  });
}

void _filterBarKeepsState() {
  testWidgets('GIVEN the chips of the filter bar on screen\n'
      'WHEN select mode starts (the header becomes pinned)\n'
      'THEN the filter bar keeps its state, it is not mounted again', (
    tester,
  ) async {
    final h = await _pumpPhone(tester);
    final before = tester.state(find.byType(RoomListFilterPills));

    await h.startSelectMode(tester);

    expect(tester.state(find.byType(RoomListFilterPills)), same(before));
  });
}

void _hiddenAboveScreen() {
  testWidgets('GIVEN the list scrolled down with a status bar\n'
      'THEN the header is entirely above the screen, nothing of it shows', (
    tester,
  ) async {
    await _pumpPhone(tester);
    tester.takeException();

    await scrollDown(tester, 600);

    expect(headerVisible(tester), isFalse);
    // Either not built at all, or built and entirely above the screen.
    if (headerFinder.evaluate().isNotEmpty) {
      expect(tester.getRect(headerFinder).bottom, lessThanOrEqualTo(0));
    }
  });
}

void _backgroundColour() {
  group('[ChatList] header background colour on a one column layout', () {
    testWidgets('GIVEN the header comes back after a scroll\n'
        'THEN its background is the colour it has at the top of the list', (
      tester,
    ) async {
      final h = await _pumpPhone(tester);
      final atTop = await backgroundColor(tester);

      await _scrollAwayAndBack(tester, 400);
      expect(headerVisible(tester), isTrue);
      final comeBack = await backgroundColor(tester);
      expect(h.scroll.offset, greaterThan(0));

      expect(comeBack, atTop, reason: 'top $atTop, after scroll $comeBack');
    });

    testWidgets('GIVEN select mode, pinned, after a scroll\n'
        'THEN its background is the colour it has in select mode at the top', (
      tester,
    ) async {
      final h = await _pumpPhone(tester);
      await h.startSelectMode(tester);
      final atTop = await backgroundColor(tester);

      await _scrollAwayAndBack(tester, 400);
      final scrolled = await backgroundColor(tester);
      expect(h.scroll.offset, greaterThan(0));

      expect(scrolled, atTop, reason: 'top $atTop, after scroll $scrolled');
    });
  });
}

void _statusBarBand() {
  group('[ChatList] status bar band on a one column layout', () {
    _bandOnScroll();
    _bandOnWideScreen();
    _bandOnEmptyViews();
  });
}

void _bandOnScroll() {
  testWidgets('GIVEN the header is hidden by the scroll\n'
      'THEN the status bar band has the colour it has at the top', (
    tester,
  ) async {
    await _pumpPhone(tester);
    final atTop = await bandColor(tester);

    await scrollDown(tester, 400);
    expect(headerVisible(tester), isFalse);

    expect(await bandColor(tester), atTop);
  });

  testWidgets('GIVEN select mode, pinned, after a scroll\n'
      'THEN the band has the colour it has in select mode at the top', (
    tester,
  ) async {
    final h = await _pumpPhone(tester);
    await h.startSelectMode(tester);
    final atTop = await bandColor(tester);

    await scrollDown(tester, 400);

    expect(await bandColor(tester), atTop);
  });

  testWidgets('GIVEN the header comes back after a scroll\n'
      'THEN the band has the colour it has at the top', (tester) async {
    await _pumpPhone(tester);
    final atTop = await bandColor(tester);

    await _scrollAwayAndBack(tester, 400);
    expect(headerVisible(tester), isTrue);

    expect(await bandColor(tester), atTop);
  });

  testWidgets('GIVEN the list scrolls further down\n'
      'THEN no row is painted in the band: its pixel never changes', (
    tester,
  ) async {
    await _pumpPhone(tester);
    final atTop = await bandColor(tester);

    await scrollDown(tester, 400);
    final first = await bandColor(tester);
    await scrollDown(tester, 800);
    final second = await bandColor(tester);

    expect(first, atTop);
    expect(second, atTop);
  });
}

void _bandOnWideScreen() {
  testWidgets('GIVEN a wide screen scrolled down\n'
      'THEN the band stays opaque, the app bar still covers it', (
    tester,
  ) async {
    await HeaderHarness.pump(
      tester,
      const HeaderView.wide(topInset: statusBar),
    );

    await scrollDown(tester, 400);

    expect((await bandColor(tester)).a, 1.0);
  });
}

void _bandOnEmptyViews() {
  final emptyViews = {
    for (final e in headerBranches.entries)
      if (e.value.roomCount == 0) e.key: e.value,
  };
  for (final entry in emptyViews.entries) {
    testWidgets('GIVEN ${entry.key} with a status bar\n'
        'THEN the band is opaque and the colour of the header', (tester) async {
      await _pumpPhone(tester, branch: entry.value);

      final band = await bandColor(tester);
      expect(band.a, 1.0);
      expect(band, await backgroundColor(tester));
    });
  }
}
