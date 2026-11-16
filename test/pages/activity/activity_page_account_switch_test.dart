import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_test_support.dart';

/// THR-M-12: the filter and the search of the Activity are kept while the
/// user comes and goes (activity_page_back_keeps_filter_test.dart), but they
/// belong to the account: after a switch of account the Activity starts
/// again on « All », with nothing typed in the search.
void main() {
  late FakeActivityRepository repository;

  setUp(() {
    repository = FakeActivityRepository(
      items: [
        UnreadRoomItem(
          roomId: '!sales:example.org',
          roomName: 'Sales',
          time: 11.today,
          lastMessage: 'numbers are in',
        ).item,
        FollowedThreadItem(
          roomId: '!design:example.org',
          roomName: 'Design',
          rootId: r'$release',
          time: 9.today,
          lastReply: 'Ship it',
        ).item,
      ],
    );
  });

  bool shows(String text) =>
      find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

  String typed(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).controller.text;

  /// « Replies » chosen and « ship » typed: only the thread shows.
  Future<void> chooseRepliesAndSearch(WidgetTester tester) async {
    await selectFilter(tester, 'Replies');
    await tester.enterText(find.byType(TextField), 'ship');
    await tester.pumpAndSettle();
    expect(shows('Ship it'), isTrue);
    expect(shows('numbers are in'), isFalse);
  }

  testWidgets('after a switch of account, the filter is « All » again', (
    tester,
  ) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await chooseRepliesAndSearch(tester);

    await switchActiveAccount(tester, accountClient('@other:example.org'));

    expect(shows('numbers are in'), isTrue, reason: '« All » shows the rooms');
    expect(shows('Ship it'), isTrue);
  });

  testWidgets('after a switch of account, the search is empty', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await chooseRepliesAndSearch(tester);

    await switchActiveAccount(tester, accountClient('@other:example.org'));

    expect(typed(tester), isEmpty);
  });

  testWidgets('without a switch, the filter and the search stay', (
    tester,
  ) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await chooseRepliesAndSearch(tester);

    await tester.pumpAndSettle();

    expect(typed(tester), 'ship');
    expect(shows('numbers are in'), isFalse);
  });
}
