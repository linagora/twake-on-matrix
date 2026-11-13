import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_test_support.dart';

/// THR-M-12, slice 1, found on the real app (QA 2026-11-12): the filter
/// « Unread » named the rooms that have unread messages with the label of
/// the action « Mark as unread » (French « Marquer comme non lu »), shrunk
/// to a few pixels to fit the chip. The filter has a label of its own,
/// read at its font size.
void main() {
  late FakeActivityRepository repository;

  setUp(() {
    repository = FakeActivityRepository(
      items: [
        UnreadRoomItem(
          roomId: '!design:example.org',
          roomName: 'Design',
          time: 10.today,
        ).item,
      ],
    );
  });

  testWidgets('in French, the filter of the unread rooms is not the action '
      '« Marquer comme non lu »', (tester) async {
    await pumpActivityPage(
      tester,
      ActivityPageSetup(repository: repository, locale: const Locale('fr')),
    );

    expect(find.text('Marquer comme non lu'), findsNothing);
  });

  /// The test font draws every letter one em wide: a label longer than its
  /// chip is shrunk even in English. The label of the unread rooms is
  /// compared with « Mentions », as long as the longest real label.
  testWidgets('in French, the filter of the unread rooms is drawn no smaller '
      'than « Mentions »', (tester) async {
    await pumpActivityPage(
      tester,
      ActivityPageSetup(repository: repository, locale: const Locale('fr')),
    );

    final labels = find.descendant(
      of: find.byType(ChoiceChip),
      matching: find.byType(Text),
    );
    expect(labels, findsNWidgets(4));
    // All, Unread, Mentions, Replies: the order the filters keep.
    final unread = tester.getRect(labels.at(1)).height;
    final mentions = tester.getRect(find.text('Mentions')).height;

    expect(unread, greaterThanOrEqualTo(mentions));
  });

  testWidgets('in English, the filter of the unread rooms reads « Unread » '
      'and still shows them', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

    await selectFilter(tester, 'Unread');

    expect(find.text('Mark as read'), findsOneWidget);
  });
}
