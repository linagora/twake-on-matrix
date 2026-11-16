import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_mentions_test_support.dart';
import 'activity_reactions_test_support.dart';
import 'activity_test_support.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 3: the
/// search keeps the items whose author, room, thread or quoted message
/// holds every word typed, accents aside (web D221, `searchFeed`).
void main() {
  late FakeActivityRepository repository;
  late FakeActivityMentionsRepository mentions;
  late FakeActivityReactionsRepository reactions;

  setUp(() {
    repository = FakeActivityRepository(
      items: [
        UnreadRoomItem(
          roomId: '!cafe:example.org',
          roomName: 'Café du coin',
          time: 12.today,
          author: 'Bob Martin',
          lastMessage: 'numbers are in',
        ).item,
        FollowedThreadItem(
          roomId: '!design:example.org',
          roomName: 'Design',
          rootId: r'$release',
          rootText: 'Release plan for Friday',
          time: 10.today,
          author: 'Alice Durand',
          lastReply: 'Ship it',
        ).item,
      ],
    );
    mentions = FakeActivityMentionsRepository(
      mentions: [
        MentionItem(
          roomId: '!sales:example.org',
          roomName: 'Sales',
          eventId: r'$ask',
          time: 11.today,
          author: 'Dan Brown',
          text: 'le résumé est prêt',
        ).item,
      ],
    );
    reactions = FakeActivityReactionsRepository(
      reactions: [
        ReactionItem(
          roomId: '!sales:example.org',
          roomName: 'Sales',
          eventId: r'$deck',
          time: 9.today,
          author: 'Frank Moore',
          message: 'the deck is ready',
        ).item,
      ],
    );
  });

  Future<void> pump(WidgetTester tester) {
    return pumpActivityPage(
      tester,
      ActivityPageSetup(
        repository: repository,
        mentions: mentions,
        reactions: reactions,
      ),
    );
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  bool shows(String quote) =>
      find.textContaining(quote, findRichText: true).evaluate().isNotEmpty;

  const allQuotes = [
    'numbers are in',
    'Ship it',
    'le résumé est prêt',
    'the deck is ready',
  ];

  Map<String, bool> shown() => {
    for (final quote in allQuotes) quote: shows(quote),
  };

  testWidgets('the page has a search field', (tester) async {
    await pump(tester);

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('a word of the author keeps the items of that author', (
    tester,
  ) async {
    await pump(tester);
    await search(tester, 'Durand');

    expect(shown(), {
      'numbers are in': false,
      'Ship it': true,
      'le résumé est prêt': false,
      'the deck is ready': false,
    });
  });

  testWidgets('a word of the room keeps the items of that room', (
    tester,
  ) async {
    await pump(tester);
    await search(tester, 'Sales');

    expect(shown(), {
      'numbers are in': false,
      'Ship it': false,
      'le résumé est prêt': true,
      'the deck is ready': true,
    });
  });

  testWidgets('a word of the thread keeps the items of that thread', (
    tester,
  ) async {
    await pump(tester);
    await search(tester, 'Friday');

    expect(shown(), {
      'numbers are in': false,
      'Ship it': true,
      'le résumé est prêt': false,
      'the deck is ready': false,
    });
  });

  testWidgets('a word of the quoted message keeps the items that quote it', (
    tester,
  ) async {
    await pump(tester);
    await search(tester, 'deck');

    expect(shown(), {
      'numbers are in': false,
      'Ship it': false,
      'le résumé est prêt': false,
      'the deck is ready': true,
    });
  });

  testWidgets('every word typed must be found, wherever in the item', (
    tester,
  ) async {
    await pump(tester);

    // « Alice » is the author, « ship » the quote: the same item.
    await search(tester, 'alice ship');
    expect(shows('Ship it'), isTrue);

    // « Alice » and « deck » are in two different items.
    await search(tester, 'alice deck');
    expect(shown().values, everyElement(isFalse));
  });

  testWidgets('accents do not matter, in the text nor in what is typed', (
    tester,
  ) async {
    await pump(tester);

    await search(tester, 'resume pret');
    expect(shows('le résumé est prêt'), isTrue);

    await search(tester, 'cafe');
    expect(shows('numbers are in'), isTrue, reason: 'room « Café du coin »');

    await search(tester, 'Désign');
    expect(shows('Ship it'), isTrue, reason: 'room « Design »');
  });

  testWidgets('upper or lower case does not matter', (tester) async {
    await pump(tester);
    await search(tester, 'FRANK');

    expect(shows('the deck is ready'), isTrue);
  });

  testWidgets('the search keeps the chosen filter', (tester) async {
    await pump(tester);
    await selectFilter(tester, 'Mentions');
    await search(tester, 'Sales');

    expect(shown(), {
      'numbers are in': false,
      'Ship it': false,
      'le résumé est prêt': true,
      'the deck is ready': false,
    });
  });

  testWidgets('nothing matching: no item shows', (tester) async {
    await pump(tester);
    await search(tester, 'zebra');

    expect(shown().values, everyElement(isFalse));
  });

  testWidgets('clearing the search shows every item again', (tester) async {
    await pump(tester);
    await search(tester, 'zebra');
    await search(tester, '');

    expect(shown().values, everyElement(isTrue));
  });
}
