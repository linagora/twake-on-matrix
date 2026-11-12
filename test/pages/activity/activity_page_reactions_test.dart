import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';

import 'activity_mentions_test_support.dart';
import 'activity_reactions_test_support.dart';
import 'activity_test_support.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 3: « All »
/// is the unread rooms, the mentions, the followed threads and the
/// reactions of the others to the messages of the user, newest first; the
/// reactions show in « All » only (web D58, D185). Touching a reaction opens
/// the message, in its thread when it is a thread reply.
void main() {
  late FakeActivityRepository repository;
  late FakeActivityMentionsRepository mentions;
  late FakeActivityReactionsRepository reactions;

  const designId = '!design:example.org';

  final onDeck = reactionItem(
    roomId: designId,
    roomName: 'Design',
    eventId: r'$deck',
    time: todayAt(10, 30),
    author: 'Frank Moore',
    emoji: '🎉',
    message: 'the deck is ready',
  );
  final inThread = reactionItem(
    roomId: designId,
    roomName: 'Design',
    eventId: r'$my_reply',
    time: todayAt(7),
    author: 'Grace Hall',
    emoji: '👍',
    message: 'I can take it',
    rootId: r'$release',
    rootText: 'Release plan for Friday',
  );

  setUp(() {
    repository = FakeActivityRepository(
      items: [
        unreadRoomItem(
          roomId: '!sales:example.org',
          roomName: 'Sales',
          time: todayAt(12),
          lastMessage: 'numbers are in',
        ),
        followedThreadItem(
          roomId: designId,
          roomName: 'Design',
          rootId: r'$other',
          time: todayAt(10),
          lastReply: 'Ship it',
        ),
      ],
    );
    mentions = FakeActivityMentionsRepository(
      mentions: [
        mentionItem(
          roomId: designId,
          roomName: 'Design',
          eventId: r'$ask',
          time: todayAt(11),
          text: '@me can you check?',
        ),
      ],
    );
    reactions = FakeActivityReactionsRepository(reactions: [onDeck, inThread]);
  });

  Future<void> pump(WidgetTester tester) {
    return pumpActivityPage(
      tester,
      repository: repository,
      mentions: mentions,
      reactions: reactions,
    );
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.textContaining(text, findRichText: true).first).dy;

  testWidgets('« All » shows a reaction: who, the emoji and the message of '
      'the user', (tester) async {
    await pump(tester);

    expect(
      find.textContaining('Frank Moore', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('🎉', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('the deck is ready', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('« All » is every kind, newest first', (tester) async {
    await pump(tester);

    final order = [
      top(tester, 'numbers are in'), // unread room, 12:00
      top(tester, 'can you check?'), // mention, 11:00
      top(tester, 'the deck is ready'), // reaction, 10:30
      top(tester, 'Ship it'), // followed thread, 10:00
      top(tester, 'I can take it'), // reaction, 7:00
    ];
    expect(order, orderedEquals([...order]..sort()));
  });

  for (final filter in ['Unread', 'Mentions', 'Replies']) {
    testWidgets('the reactions show in « All » only, not in « $filter »', (
      tester,
    ) async {
      await pump(tester);
      await selectFilter(tester, filter);

      expect(
        find.textContaining('the deck is ready', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('I can take it', findRichText: true),
        findsNothing,
      );
    });
  }

  testWidgets('touching a reaction opens the room on the message', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(
      find.textContaining('the deck is ready', findRichText: true),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        openedText(const RoomRoute(roomid: designId, event: r'$deck').location),
      ),
      findsOneWidget,
    );
  });

  testWidgets('touching a reaction to a thread reply opens the thread on the '
      'message', (tester) async {
    await pump(tester);

    await tester.tap(find.textContaining('I can take it', findRichText: true));
    await tester.pumpAndSettle();

    expect(
      find.text(
        openedText(
          const ThreadRoute(
            roomid: designId,
            rootid: r'$release',
            event: r'$my_reply',
          ).location,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a new reaction shows without a refresh, a reaction taken back '
      'leaves', (tester) async {
    await pump(tester);

    reactions.emit([
      reactionItem(
        roomId: designId,
        roomName: 'Design',
        eventId: r'$late',
        time: todayAt(13),
        author: 'Hugo Lane',
        emoji: '❤️',
        message: 'see the new logo',
      ),
      inThread,
    ]);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('see the new logo', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('the deck is ready', findRichText: true),
      findsNothing,
    );
  });
}
