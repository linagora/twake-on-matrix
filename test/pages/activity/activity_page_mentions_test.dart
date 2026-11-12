import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';

import 'activity_mentions_test_support.dart';
import 'activity_test_support.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 2: the
/// filter « Mentions » lists the mentions of the user, in rooms and in
/// threads, read from `/notifications`; touching one opens the message, in
/// its thread when it is a thread reply. « Mark all read » reads every
/// unread room: the unread mentions count it shows (and the tab badge) goes
/// to zero (web D568).
void main() {
  late FakeActivityRepository repository;
  late FakeActivityMentionsRepository mentions;

  const designId = '!design:example.org';
  const salesId = '!sales:example.org';
  const rootId = r'$release';

  final roomMention = mentionItem(
    roomId: designId,
    roomName: 'Design',
    eventId: r'$ask',
    time: todayAt(11, 30),
    author: 'Dan Brown',
    text: '@me can you check the mockups?',
  );
  final threadMention = mentionItem(
    roomId: designId,
    roomName: 'Design',
    eventId: r'$in_thread',
    time: todayAt(9, 30),
    author: 'Erin Gray',
    text: '@me what do you think?',
    rootId: rootId,
    rootText: 'Release plan for Friday',
  );
  final unreadDesign = unreadRoomItem(
    roomId: designId,
    roomName: 'Design',
    time: todayAt(12),
    lastMessage: 'see you there',
  );
  final unreadSales = unreadRoomItem(
    roomId: salesId,
    roomName: 'Sales',
    time: todayAt(8),
    lastMessage: 'numbers are in',
  );
  final followed = followedThreadItem(
    roomId: designId,
    roomName: 'Design',
    rootId: r'$other',
    time: todayAt(10),
    lastReply: 'Ship it',
  );

  setUp(() {
    repository = FakeActivityRepository(
      items: [unreadDesign, unreadSales, followed],
      mentionCount: 3,
      mentionsByRoom: {designId: 2, salesId: 1},
    );
    mentions = FakeActivityMentionsRepository(
      mentions: [roomMention, threadMention],
    );
  });

  Future<void> pump(WidgetTester tester) =>
      pumpActivityPage(tester, repository: repository, mentions: mentions);

  group('« Mentions »', () {
    testWidgets('lists the mentions of the user, in a room and in a thread', (
      tester,
    ) async {
      await pump(tester);
      await selectFilter(tester, 'Mentions');

      expect(
        find.textContaining('can you check the mockups?', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('what do you think?', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Dan Brown', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a mention in a thread shows the start of its root next to '
        'the room', (tester) async {
      await pump(tester);
      await selectFilter(tester, 'Mentions');

      expect(
        find.textContaining('Release plan', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('lists the mentions only, not the unread rooms nor the '
        'followed threads', (tester) async {
      await pump(tester);
      await selectFilter(tester, 'Mentions');

      expect(
        find.textContaining('see you there', findRichText: true),
        findsNothing,
      );
      expect(find.textContaining('Ship it', findRichText: true), findsNothing);
    });

    testWidgets('touching a mention in a room opens the room on the message', (
      tester,
    ) async {
      await pump(tester);
      await selectFilter(tester, 'Mentions');

      await tester.tap(
        find.textContaining('can you check the mockups?', findRichText: true),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          openedText(
            const RoomRoute(roomid: designId, event: r'$ask').location,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('touching a mention in a thread opens the thread on the '
        'message', (tester) async {
      await pump(tester);
      await selectFilter(tester, 'Mentions');

      await tester.tap(
        find.textContaining('what do you think?', findRichText: true),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          openedText(
            const ThreadRoute(
              roomid: designId,
              rootid: rootId,
              event: r'$in_thread',
            ).location,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('while the mentions load, a progress shows', (tester) async {
      mentions.gate = Completer<void>();
      await pumpActivityPage(
        tester,
        repository: repository,
        mentions: mentions,
        settle: false,
      );
      await selectFilter(tester, 'Mentions', settle: false);

      expect(
        find.byWidgetPredicate((widget) => widget is ProgressIndicator),
        findsWidgets,
      );

      mentions.gate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((widget) => widget is ProgressIndicator),
        findsNothing,
      );
      expect(
        find.textContaining('can you check the mockups?', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('when the mentions cannot be read, « Try again » reads them '
        'again', (tester) async {
      mentions.error = Exception('offline');
      await pump(tester);
      await selectFilter(tester, 'Mentions');

      expect(
        find.textContaining('can you check the mockups?', findRichText: true),
        findsNothing,
      );
      expect(find.text('Try again'), findsOneWidget);

      mentions.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('can you check the mockups?', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('when the mentions cannot be read, the other items still '
        'show in « All »', (tester) async {
      mentions.error = Exception('offline');
      await pump(tester);

      expect(
        find.textContaining('see you there', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Ship it', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('« All »', () {
    testWidgets('adds the mentions to the unread rooms and the followed '
        'threads, newest first', (tester) async {
      await pump(tester);

      double top(String text) => tester
          .getTopLeft(find.textContaining(text, findRichText: true).first)
          .dy;
      final order = [
        top('see you there'), // 12:00
        top('can you check the mockups?'), // 11:30
        top('Ship it'), // 10:00
        top('what do you think?'), // 9:30
        top('numbers are in'), // 8:00
      ];
      expect(order, orderedEquals([...order]..sort()));
    });
  });

  group('« Mark all read »', () {
    testWidgets('reads every unread room', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(repository.markedRead, unorderedEquals([designId, salesId]));
    });

    testWidgets('takes the unread mentions count of the title to zero', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('empties « Unread »', (tester) async {
      await pump(tester);
      await selectFilter(tester, 'Unread');

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(find.text('Mark as read'), findsNothing);
      expect(
        find.textContaining('see you there', findRichText: true),
        findsNothing,
      );
    });
  });
}
