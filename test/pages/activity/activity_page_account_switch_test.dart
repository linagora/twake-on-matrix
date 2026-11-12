import 'package:flutter_test/flutter_test.dart';

import 'activity_test_support.dart';

/// THR-M-12: the filter of the Activity is kept while the user comes and
/// goes (activity_page_back_keeps_filter_test.dart), but it belongs to the
/// account: after a switch of account the Activity starts again on « All ».
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

  /// « Replies » chosen: only the thread shows.
  Future<void> chooseReplies(WidgetTester tester) async {
    await selectFilter(tester, 'Replies');
    expect(shows('Ship it'), isTrue);
    expect(shows('numbers are in'), isFalse);
  }

  testWidgets('after a switch of account, the filter is « All » again', (
    tester,
  ) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await chooseReplies(tester);

    await switchActiveAccount(tester, accountClient('@other:example.org'));

    expect(shows('numbers are in'), isTrue, reason: '« All » shows the rooms');
    expect(shows('Ship it'), isTrue);
  });

  testWidgets('without a switch, the filter stays', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await chooseReplies(tester);

    await tester.pumpAndSettle();

    expect(shows('numbers are in'), isFalse);
  });
}
