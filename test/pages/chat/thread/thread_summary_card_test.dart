import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/thread/thread_summary_card.dart';

/// THR-M-02: the card under a thread root.
void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    int replyCount = 3,
    int unreadCount = 0,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.supportedLocales,
      home: Scaffold(
        body: ThreadSummaryCard(
          replyCount: replyCount,
          lastReplyAuthor: 'Alice',
          lastReplyText: 'See you tomorrow',
          lastReplyTime: DateTime.now().subtract(const Duration(minutes: 5)),
          unreadCount: unreadCount,
          onTap: onTap ?? () {},
        ),
      ),
    ),
  );

  testWidgets('shows the number of messages of the thread', (tester) async {
    await pumpCard(tester, replyCount: 3);

    expect(
      find.textContaining('3 messages', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('shows the author and the text of the last reply', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.textContaining('Alice', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('See you tomorrow', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('announces the unread messages to accessibility', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(tester, unreadCount: 2);

    expect(find.bySemanticsLabel(RegExp('2 unread messages')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('announces no unread messages when the thread is read', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(tester);

    expect(find.bySemanticsLabel(RegExp('unread messages')), findsNothing);
    semantics.dispose();
  });

  testWidgets('tapping the card opens the thread', (tester) async {
    var opened = 0;
    await pumpCard(tester, onTap: () => opened++);

    await tester.tap(find.textContaining('3 messages', findRichText: true));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('the card is reachable as a button by accessibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(tester);

    expect(
      tester.getSemantics(find.byType(ThreadSummaryCard)),
      containsSemantics(isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });
}
