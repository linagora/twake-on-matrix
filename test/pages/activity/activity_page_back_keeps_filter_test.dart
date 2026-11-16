import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_test_support.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md): « Ouvrir un
/// élément depuis l'onglet Activité puis revenir ramène à l'onglet
/// Activité, au même filtre. » What was typed in the search stays too. On a
/// phone the item is pushed over the tab; on a wide screen it replaces the
/// tab's page, which is built again when the user comes back.
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
        UnreadRoomItem(
          roomId: '!ops:example.org',
          roomName: 'Ops',
          time: 10.today,
          lastMessage: 'server is down',
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

  Future<void> openThenBack(WidgetTester tester, String quote) async {
    await tester.tap(find.textContaining(quote, findRichText: true));
    await tester.pumpAndSettle();
    expect(find.textContaining('opened'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
  }

  for (final wide in [false, true]) {
    final screen = wide ? 'on a wide screen' : 'on a phone';

    group(screen, () {
      testWidgets('back from a followed thread, « Replies » is still the '
          'filter', (tester) async {
        await pumpActivityPage(
          tester,
          ActivityPageSetup(repository: repository, wide: wide),
        );
        await selectFilter(tester, 'Replies');

        await openThenBack(tester, 'Ship it');

        expect(shows('Ship it'), isTrue);
        expect(
          shows('numbers are in'),
          isFalse,
          reason: 'the unread rooms stay out: the filter is « Replies »',
        );
      });

      testWidgets('back from an unread room, « Unread » and the search typed '
          'are still there', (tester) async {
        await pumpActivityPage(
          tester,
          ActivityPageSetup(repository: repository, wide: wide),
        );
        await selectFilter(tester, 'Unread');
        await tester.enterText(find.byType(TextField), 'sales');
        await tester.pumpAndSettle();
        expect(shows('server is down'), isFalse);

        await openThenBack(tester, 'numbers are in');

        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          'sales',
        );
        expect(shows('numbers are in'), isTrue);
        expect(
          shows('server is down'),
          isFalse,
          reason: 'the search still keeps Sales only',
        );
        expect(
          shows('Ship it'),
          isFalse,
          reason: 'the filter is still « Unread »',
        );
      });
    });
  }
}
