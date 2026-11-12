import 'package:flutter_test/flutter_test.dart';

import 'activity_test_support.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md): « Ouvrir un
/// élément depuis l'onglet Activité puis revenir ramène à l'onglet
/// Activité, au même filtre. » On a
/// phone the item is pushed over the tab; on a wide screen it replaces the
/// tab's page, which is built again when the user comes back.
void main() {
  late FakeActivityRepository repository;

  setUp(() {
    repository = FakeActivityRepository(
      items: [
        unreadRoomItem(
          roomId: '!sales:example.org',
          roomName: 'Sales',
          time: todayAt(11),
          lastMessage: 'numbers are in',
        ),
        unreadRoomItem(
          roomId: '!ops:example.org',
          roomName: 'Ops',
          time: todayAt(10),
          lastMessage: 'server is down',
        ),
        followedThreadItem(
          roomId: '!design:example.org',
          roomName: 'Design',
          rootId: r'$release',
          time: todayAt(9),
          lastReply: 'Ship it',
        ),
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
        await pumpActivityPage(tester, repository: repository, wide: wide);
        await selectFilter(tester, 'Replies');

        await openThenBack(tester, 'Ship it');

        expect(shows('Ship it'), isTrue);
        expect(
          shows('numbers are in'),
          isFalse,
          reason: 'the unread rooms stay out: the filter is « Replies »',
        );
      });

      testWidgets('back from an unread room, « Unread » is still the filter', (
        tester,
      ) async {
        await pumpActivityPage(tester, repository: repository, wide: wide);
        await selectFilter(tester, 'Unread');
        expect(shows('Ship it'), isFalse);

        await openThenBack(tester, 'numbers are in');

        expect(shows('numbers are in'), isTrue);
        expect(shows('server is down'), isTrue);
        expect(
          shows('Ship it'),
          isFalse,
          reason: 'the filter is still « Unread »',
        );
      });
    });
  }
}
