import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:twake_chat/pages/chat/events/message/message_reaction_dialog.dart';

import 'message_reaction_dialog_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<Room>(),
  MockSpec<Event>(),
  MockSpec<Timeline>(),
])
void main() {
  const myUserId = '@me:localhost';
  late List<String> calls;
  late MockEvent event;
  late MockEvent myReaction;
  late MockTimeline timeline;

  setUp(() {
    calls = [];
    final client = MockClient();
    final room = MockRoom();
    event = MockEvent();
    myReaction = MockEvent();
    timeline = MockTimeline();

    when(client.userID).thenReturn(myUserId);
    when(room.client).thenReturn(client);
    when(event.room).thenReturn(room);
    when(event.senderId).thenReturn('@other:localhost');
    when(myReaction.room).thenReturn(room);
    when(myReaction.senderId).thenReturn(myUserId);
    when(myReaction.type).thenReturn(EventTypes.Reaction);
    when(myReaction.content).thenReturn({
      'm.relates_to': {
        'rel_type': RelationshipTypes.reaction,
        'event_id': r'$message',
        'key': '👍',
      },
    });
    when(myReaction.redactEvent()).thenAnswer((_) async {
      calls.add('redact');
      return null;
    });
    when(
      event.aggregatedEvents(timeline, RelationshipTypes.reaction),
    ).thenReturn({myReaction});
  });

  Future<void> pumpDialog(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MessageReactionDialog(
          event: event,
          timeline: timeline,
          displayEmojiPicker: ValueNotifier(false),
          messageWidget: const SizedBox(),
          emojiPickerBuilder:
              ({
                required emojiData,
                required myReaction,
                required event,
                required relatesTo,
              }) => const SizedBox(),
          messageContextMenu: (_) => [],
          themeContextMenu: (_) => const PullDownMenuItemTheme(),
          iconContextMenu: (_, _) => null,
          dialogSafeAreaKey: GlobalKey(),
          onToggleEmojiReaction: (emoji, _) async {
            calls.add('toggle $emoji');
          },
        ),
      ),
    ),
  );

  testWidgets('hands another reaction to the toggle callback', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('😂'));
    await tester.pump();

    expect(calls, ['toggle 😂']);
  });

  testWidgets('hands the current reaction to the toggle callback', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.text('👍'));
    await tester.pump();

    expect(calls, ['toggle 👍']);
  });
}
