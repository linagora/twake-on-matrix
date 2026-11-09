import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/message_reactions.dart';
import 'package:twake_chat/pages/chat/events/message_reactions_bottom_sheet.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/mxc_image.dart';

import 'message_reactions_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Room>(),
  MockSpec<Event>(),
  MockSpec<Client>(),
  MockSpec<User>(),
])
void main() {
  const myUserId = '@me:example.com';
  const messageId = r'$message';
  const customEmoji = 'mxc://example.com/party';

  late MockClient client;
  late MockRoom room;
  late MockEvent message;

  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  setUp(() {
    client = MockClient();
    room = MockRoom();
    message = MockEvent();
    when(client.userID).thenReturn(myUserId);
    when(room.client).thenReturn(client);
    when(room.isDirectChat).thenReturn(false);
    when(message.room).thenReturn(room);
    when(message.eventId).thenReturn(messageId);
  });

  MockUser user(String name) {
    final user = MockUser();
    when(user.calcDisplayname()).thenReturn(name);
    return user;
  }

  ReactionEntry reaction(
    String key, {
    int count = 1,
    bool reacted = false,
    List<User>? reactors,
  }) => ReactionEntry(
    key: key,
    count: count,
    reacted: reacted,
    reactors: reactors ?? [for (var i = 0; i < count; i++) user('$key $i')],
  );

  MockEvent reactionEvent(
    String key, {
    String senderId = myUserId,
    DateTime? sentAt,
  }) {
    final event = MockEvent();
    final sender = user(senderId);
    when(event.room).thenReturn(room);
    when(event.senderId).thenReturn(senderId);
    when(event.originServerTs).thenReturn(sentAt ?? DateTime(2026));
    when(event.senderFromMemoryOrFallback).thenReturn(sender);
    when(event.content).thenReturn({
      'm.relates_to': {
        'rel_type': RelationshipTypes.reaction,
        'event_id': messageId,
        'key': key,
      },
    });
    return event;
  }

  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    home: Scaffold(body: child),
  );

  Future<void> pumpReactions(
    WidgetTester tester,
    List<ReactionEntry> reactions, {
    Set<Event> allReactionEvents = const {},
  }) => tester.pumpWidget(
    app(
      Align(
        alignment: Alignment.topLeft,
        child: ReactionsList(
          reactionList: reactions,
          allReactionEvents: allReactionEvents,
          event: message,
          client: client,
        ),
      ),
    ),
  );

  group('groupReactions', () {
    const bob = '@bob:example.com';
    const carol = '@carol:example.com';
    const thumbsUpVs16 = '👍\uFE0F';
    const thumbsUpVs15 = '👍\uFE0E';

    test('merges keys that differ only by a variation selector', () {
      final reactions = groupReactions([
        reactionEvent('👍', senderId: bob),
        reactionEvent(thumbsUpVs16, senderId: carol),
        reactionEvent(thumbsUpVs15),
      ], myUserId);

      expect(reactions, hasLength(1));
      expect(reactions.single.key, '👍');
      expect(reactions.single.count, 3);
      expect(reactions.single.reactors, hasLength(3));
      expect(reactions.single.reacted, isTrue);
    });

    test('marks as reacted when my reaction used the other variant', () {
      final reactions = groupReactions([
        reactionEvent('👍', senderId: bob),
        reactionEvent(thumbsUpVs16),
      ], myUserId);

      expect(reactions.single.reacted, isTrue);
    });

    test('counts a sender once when they sent both variants', () {
      final reactions = groupReactions([
        reactionEvent('👍', senderId: bob),
        reactionEvent(thumbsUpVs16, senderId: bob),
      ], myUserId);

      expect(reactions.single.count, 1);
      expect(reactions.single.reacted, isFalse);
    });

    test('keeps different emojis apart', () {
      final reactions = groupReactions([
        reactionEvent('👍'),
        reactionEvent('❤️', senderId: bob),
        reactionEvent('❤️', senderId: carol),
      ], myUserId);

      expect(reactions.map((r) => (r.key, r.count)), [('❤️', 2), ('👍', 1)]);
    });

    test('orders equal counts by first reaction, whatever the arrival', () {
      final events = [
        for (final (i, key) in ['👍', '❤️', '😂', '🎉', '🔥'].indexed)
          reactionEvent(
            key,
            senderId: '@user$i:example.com',
            sentAt: DateTime(2026, 1, 1, 0, i),
          ),
      ];

      final live = groupReactions(events, myUserId);
      final fromHistory = groupReactions(events.reversed, myUserId);

      const expected = ['👍', '❤️', '😂', '🎉', '🔥'];
      expect(live.map((r) => r.key), expected);
      expect(fromHistory.map((r) => r.key), expected);
    });

    test('dates a group by its earliest event, even a duplicate sender', () {
      final events = [
        reactionEvent(
          thumbsUpVs16,
          senderId: bob,
          sentAt: DateTime(2026, 1, 1, 0, 5),
        ),
        reactionEvent('👍', senderId: bob, sentAt: DateTime(2026, 1, 1, 0, 1)),
        reactionEvent(
          '❤️',
          senderId: carol,
          sentAt: DateTime(2026, 1, 1, 0, 3),
        ),
      ];

      final live = groupReactions(events, myUserId);
      final fromHistory = groupReactions(events.reversed, myUserId);

      expect(live.map((r) => r.key), [thumbsUpVs16, '❤️']);
      expect(fromHistory.map((r) => r.key), ['👍', '❤️']);
    });

    test('breaks a full tie the same way whatever the arrival', () {
      final sentAt = DateTime(2026, 1, 1);
      final events = [
        reactionEvent('😂', senderId: bob, sentAt: sentAt),
        reactionEvent('👍', senderId: carol, sentAt: sentAt),
      ];

      final live = groupReactions(events, myUserId);
      final fromHistory = groupReactions(events.reversed, myUserId);

      expect(
        live.map((r) => r.key).toList(),
        fromHistory.map((r) => r.key).toList(),
      );
    });

    test('puts a higher count first, before older reactions', () {
      final reactions = groupReactions([
        reactionEvent('👍', sentAt: DateTime(2026, 1, 1, 0, 1)),
        reactionEvent('🔥', senderId: bob, sentAt: DateTime(2026, 1, 1, 0, 2)),
        reactionEvent(
          '🔥',
          senderId: carol,
          sentAt: DateTime(2026, 1, 1, 0, 3),
        ),
      ], myUserId);

      expect(reactions.map((r) => r.key), ['🔥', '👍']);
    });
  });

  group('ReactionsList', () {
    testWidgets('hides a count of 1 and shows higher counts', (tester) async {
      await pumpReactions(tester, [reaction('👍', count: 3), reaction('🎉')]);

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('hides counts in a direct chat', (tester) async {
      when(room.isDirectChat).thenReturn(true);

      await pumpReactions(tester, [reaction('👍', count: 3)]);

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('does not open the reactions list from +N in a direct chat', (
      tester,
    ) async {
      when(room.isDirectChat).thenReturn(true);

      await pumpReactions(tester, [
        for (final key in ['👍', '🎉', '😂', '❤️', '🔥']) reaction(key),
      ]);
      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      expect(find.byType(MessageReactionsBottomSheet), findsNothing);
    });

    testWidgets('opens the reactions list from +N in a group', (tester) async {
      await pumpReactions(tester, [
        for (final key in ['👍', '🎉', '😂', '❤️', '🔥']) reaction(key),
      ]);
      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();

      expect(find.byType(MessageReactionsBottomSheet), findsOneWidget);
    });

    testWidgets('sends the reaction when not reacted yet', (tester) async {
      when(
        room.sendReaction(messageId, '👍'),
      ).thenAnswer((_) async => r'$sent');

      await pumpReactions(tester, [reaction('👍')]);
      await tester.tap(find.text('👍'));
      await tester.pump();

      verify(room.sendReaction(messageId, '👍')).called(1);
    });

    testWidgets('redacts my own reaction when already reacted', (tester) async {
      final othersReaction = reactionEvent('👍', senderId: '@bob:example.com');
      final myReaction = reactionEvent('👍');
      when(myReaction.redactEvent()).thenAnswer((_) async => r'$redaction');

      await pumpReactions(
        tester,
        [reaction('👍', count: 2, reacted: true)],
        allReactionEvents: {othersReaction, myReaction},
      );
      await tester.tap(find.text('👍'));
      await tester.pump();

      verify(myReaction.redactEvent()).called(1);
      verifyNever(othersReaction.redactEvent());
      verifyNever(room.sendReaction(any, any));
    });

    testWidgets('redacts my reaction sent with the other variant', (
      tester,
    ) async {
      final othersReaction = reactionEvent('👍', senderId: '@bob:example.com');
      final myReaction = reactionEvent('👍\uFE0F');
      when(myReaction.redactEvent()).thenAnswer((_) async => r'$redaction');

      await pumpReactions(
        tester,
        [reaction('👍', count: 2, reacted: true)],
        allReactionEvents: {othersReaction, myReaction},
      );
      await tester.tap(find.text('👍'));
      await tester.pump();

      verify(myReaction.redactEvent()).called(1);
      verifyNever(othersReaction.redactEvent());
      verifyNever(room.sendReaction(any, any));
    });

    testWidgets('shows an error when the reaction cannot be sent', (
      tester,
    ) async {
      when(room.sendReaction(messageId, '👍')).thenThrow(Exception('offline'));

      await pumpReactions(tester, [reaction('👍')]);
      await tester.tap(find.text('👍'));
      await tester.pump();

      final l10n = L10n.of(tester.element(find.byType(ReactionsList)))!;
      expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
    });

    testWidgets('displays a custom emoji as an image', (tester) async {
      await pumpReactions(tester, [reaction(customEmoji, count: 2)]);

      final image = tester.widget<MxcImage>(find.byType(MxcImage));
      expect(image.uri, Uri.parse(customEmoji));
      expect(find.text(customEmoji), findsNothing);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('labels the reactions for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();

      await pumpReactions(tester, [
        reaction('👍', count: 3),
        reaction(customEmoji),
      ]);

      expect(find.bySemanticsLabel('👍, 3 reactions'), findsOneWidget);
      expect(find.bySemanticsLabel('Custom emoji, 1 reaction'), findsOneWidget);
      expect(find.bySemanticsLabel('Show all reactions'), findsOneWidget);
      semantics.dispose();
    });
  });
}
