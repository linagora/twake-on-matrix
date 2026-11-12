import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

import 'activity_test_support.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 1: the
/// header (title « Activity » with the unread mentions count, nothing at
/// zero, web D568), the filters All / Unread / Mentions / Replies without
/// « Saved », one list newest first grouped by day (Today, Yesterday, then
/// the date), and the row: avatar, the author in bold, the time at the
/// right, the room on the second line, the quoted message on two lines at
/// most (web D185, D224).
void main() {
  late FakeActivityRepository repository;

  group('the header', () {
    testWidgets('the title « Activity » carries the unread mentions count', (
      tester,
    ) async {
      repository = FakeActivityRepository(mentionCount: 7);
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('with no unread mention, the title carries no count', (
      tester,
    ) async {
      repository = FakeActivityRepository();
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('the count follows the sync without a refresh', (tester) async {
      repository = FakeActivityRepository(mentionCount: 7);
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      repository.setMentionCount(2);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('7'), findsNothing);

      repository.setMentionCount(0);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('the filters are All, Unread, Mentions and Replies, in that '
        'order, without « Saved »', (tester) async {
      repository = FakeActivityRepository();
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      final labels = ['All', 'Unread', 'Mentions', 'Replies'];
      for (final label in labels) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      final lefts = [
        for (final label in labels) tester.getTopLeft(find.text(label)).dx,
      ];
      expect(lefts, orderedEquals([...lefts]..sort()));
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('« All » shows the unread rooms and the followed threads', (
      tester,
    ) async {
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
            time: 10.today,
            lastReply: 'Ship it',
          ).item,
        ],
      );
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
      await selectFilter(tester, 'Unread');
      await selectFilter(tester, 'All');

      expect(
        find.textContaining('numbers are in', findRichText: true),
        findsOne,
      );
      expect(find.textContaining('Ship it', findRichText: true), findsOne);
    });

    testWidgets('the page opens on « All »', (tester) async {
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
            time: 10.today,
            lastReply: 'Ship it',
          ).item,
        ],
      );
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      expect(
        find.textContaining('numbers are in', findRichText: true),
        findsOne,
      );
      expect(find.textContaining('Ship it', findRichText: true), findsOne);
    });
  });

  group('one list by day, newest first', () {
    setUp(() {
      repository = FakeActivityRepository(
        items: [
          // Given out of order: the page sorts.
          UnreadRoomItem(
            roomId: '!old:example.org',
            roomName: 'Archive',
            time: DateTime(startOfToday.year - 1, 3, 3, 9),
            author: 'Zed Old',
            lastMessage: 'old news',
          ).item,
          UnreadRoomItem(
            roomId: '!early:example.org',
            roomName: 'Early',
            time: 8.today,
            lastMessage: 'early bird',
          ).item,
          FollowedThreadItem(
            roomId: '!design:example.org',
            roomName: 'Design',
            rootId: r'$release',
            time: 18.yesterday,
            lastReply: 'last evening',
          ).item,
          UnreadRoomItem(
            roomId: '!late:example.org',
            roomName: 'Late',
            time: 9.today,
            lastMessage: 'later today',
          ).item,
        ],
      );
    });

    double top(WidgetTester tester, String text) => tester
        .getTopLeft(find.textContaining(text, findRichText: true).first)
        .dy;

    testWidgets('the days read Today, Yesterday, then the date', (
      tester,
    ) async {
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(top(tester, 'Today'), lessThan(top(tester, 'Yesterday')));
      expect(top(tester, 'Yesterday'), lessThan(top(tester, 'old news')));
    });

    testWidgets('each item sits under its day, the newest first', (
      tester,
    ) async {
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      final order = [
        'Today',
        'later today',
        'early bird',
        'Yesterday',
        'last evening',
        'old news',
      ].map((text) => top(tester, text)).toList();
      expect(order, orderedEquals([...order]..sort()));
    });

    testWidgets('an older day is headed by its date', (tester) async {
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      // Whatever the format, a header between yesterday's item and the
      // older one names its day: March 3rd of last year.
      final upper = top(tester, 'last evening');
      final lower = top(tester, 'Zed Old');
      final headers = find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data ?? '').contains('3'),
      );
      final between = headers.evaluate().where((element) {
        final dy = tester.getTopLeft(find.byWidget(element.widget)).dy;
        return dy > upper && dy < lower;
      });
      expect(between, isNotEmpty);
    });
  });

  group('a row', () {
    const longQuote =
        'This message is long enough to need more than two lines on a phone '
        'screen, so the row has to cut it after the second line and not grow '
        'any taller than that, whatever the author wrote after it in the end.';

    setUp(() {
      repository = FakeActivityRepository(
        items: [
          FollowedThreadItem(
            roomId: '!design:example.org',
            roomName: 'Design',
            rootId: r'$release',
            rootText: 'Release plan for Friday',
            time: (10, 42).today,
            author: 'Alice Durand',
            lastReply: longQuote,
          ).item,
        ],
      );
    });

    testWidgets('has an avatar', (tester) async {
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      expect(find.byType(Avatar), findsOneWidget);
    });

    testWidgets('shows the author in bold', (tester) async {
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      final weight = fontWeightOf(tester, 'Alice Durand');
      expect(weight, isNotNull);
      expect(weight!.value, greaterThanOrEqualTo(FontWeight.w600.value));
    });

    testWidgets('shows the time at the right of the author', (tester) async {
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      final time = find.textContaining('10:42', findRichText: true).first;
      final author = find.textContaining('Alice Durand', findRichText: true);
      expect(
        tester.getTopLeft(time).dx,
        greaterThan(tester.getTopRight(author.first).dx),
      );
      expect(
        tester.getCenter(time).dy,
        closeTo(tester.getCenter(author.first).dy, 12),
        reason: 'same line',
      );
    });

    testWidgets('shows the room, with the start of the root of a thread, on '
        'the second line', (tester) async {
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      final author = find.textContaining('Alice Durand', findRichText: true);
      final room = find.textContaining('Design', findRichText: true).first;
      final root = find.textContaining('Release plan', findRichText: true);
      expect(
        tester.getTopLeft(room).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(author.first).dy - 1),
      );
      expect(
        tester.getCenter(root.first).dy,
        closeTo(tester.getCenter(room).dy, 12),
        reason: 'the start of the root sits on the line of the room',
      );
    });

    testWidgets('quotes the message on two lines at most', (tester) async {
      await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

      expect(linesOf(tester, 'This message is long'), lessThanOrEqualTo(2));
    });
  });
}
