import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/message_reactions.dart';
import 'package:twake_chat/pages/chat/events/message_reactions_bottom_sheet.dart';
import 'package:twake_chat/widgets/mxc_image.dart';

import 'message_reactions_bottom_sheet_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Event>(), MockSpec<User>()])
void main() {
  const customEmoji = 'mxc://example.com/party';

  MockUser user(String name) {
    final user = MockUser();
    when(user.calcDisplayname()).thenReturn(name);
    return user;
  }

  ReactionEntry reaction(String key, List<User> reactors) => ReactionEntry(
    key: key,
    count: reactors.length,
    reacted: false,
    reactors: reactors,
  );

  Future<void> pumpSheet(WidgetTester tester, List<ReactionEntry> reactions) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: MessageReactionsBottomSheet(
              reactionList: reactions,
              allReactionEvents: {
                for (final r in reactions)
                  for (var i = 0; i < r.count; i++) MockEvent(),
              },
              scrollController: ScrollController(),
            ),
          ),
        ),
      );

  testWidgets('lists every reactor on the All tab', (tester) async {
    await pumpSheet(tester, [
      reaction('👍', [user('alice'), user('bob')]),
      reaction('🎉', [user('carol')]),
    ]);

    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(find.text('carol'), findsOneWidget);
  });

  testWidgets('filters the reactors by the selected tab', (tester) async {
    await pumpSheet(tester, [
      reaction('👍', [user('alice'), user('bob')]),
      reaction('🎉', [user('carol')]),
    ]);

    await tester.tap(find.text('🎉 1'));
    await tester.pumpAndSettle();

    expect(find.text('alice'), findsNothing);
    expect(find.text('bob'), findsNothing);
    expect(find.text('carol'), findsOneWidget);
  });

  testWidgets('shows a custom emoji tab as an image', (tester) async {
    await pumpSheet(tester, [
      reaction(customEmoji, [user('alice')]),
    ]);

    expect(find.text(customEmoji), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is MxcImage && w.uri == Uri.parse(customEmoji),
      ),
      findsWidgets,
    );
  });
}
