import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/typing_timer_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'typing_timer_wrapper_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>(), MockSpec<Client>(), MockSpec<L10n>()])
void main() {
  testWidgets('typing timer wrapper should stop showing typing after 30s', (
    tester,
  ) async {
    final room = MockRoom();
    final client = MockClient();
    final l10n = MockL10n();
    const typingText = 'typing';
    const notTypingText = 'not typing';
    const typingWidget = Text(typingText);
    const notTypingWidget = Text(notTypingText);
    when(client.userID).thenReturn('owner');
    when(room.client).thenReturn(client);
    when(room.typingUsers).thenReturn([]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TypingTimerWrapper(
            room: room,
            l10n: l10n,
            typingWidget: typingWidget,
            notTypingWidget: notTypingWidget,
          ),
        ),
      ),
    );
    expect(find.text(notTypingText), findsOneWidget);
    expect(find.text(typingText), findsNothing);

    when(room.typingUsers).thenReturn([User('id', room: room)]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TypingTimerWrapper(
            room: room,
            l10n: l10n,
            typingWidget: typingWidget,
            notTypingWidget: notTypingWidget,
          ),
        ),
      ),
    );
    expect(find.text(typingText), findsOneWidget);
    expect(find.text(notTypingText), findsNothing);

    await tester.pump(const Duration(seconds: 30));
    expect(find.text(notTypingText), findsOneWidget);
    expect(find.text(typingText), findsNothing);
  });
}
