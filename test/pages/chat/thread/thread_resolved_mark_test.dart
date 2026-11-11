import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/thread/thread_app_bar_title.dart';
import 'package:twake_chat/pages/chat/thread/thread_summary_card.dart';

import 'pseudo_l10n.dart';

/// THR-M-02, THR-M-04 and THR-M-08: a resolved thread carries a check
/// « Resolved » in the header of the thread screen and on its
/// card under the root; an open one carries none.
void main() {
  group('the header of the thread', _headerTests);
  group('the card of the thread', _cardTests);
}

final _resolvedMark = find.bySemanticsLabel(RegExp('Resolved'));

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  LocalizationsDelegate<L10n> strings = L10n.delegate,
}) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: [
      strings,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: LocalizationService.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  ),
);

/// The word of the app locale for « Resolved », not one written in the
/// code (see [PseudoL10nDelegate]).
Future<void> _expectMarkInAppLocale(WidgetTester tester, Widget child) async {
  await _pump(tester, child, strings: const PseudoL10nDelegate());

  expect(
    find.bySemanticsLabel(RegExp(RegExp.escape(pseudo('Resolved')))),
    findsWidgets,
  );
}

/// Whether the thread is resolved.
enum _Thread {
  open,
  resolved;

  bool get isResolved => this == resolved;
}

Widget _header(_Thread thread) => ThreadAppBarTitle(
  rootText: 'Lunch on Friday?',
  isResolved: thread.isResolved,
);

Widget _card(_Thread thread) => ThreadSummaryCard(
  replyCount: 3,
  lastReplyAuthor: 'Bob',
  lastReplyText: 'count me in',
  lastReplyTime: DateTime.now().subtract(const Duration(minutes: 5)),
  isResolved: thread.isResolved,
  onTap: () {},
);

void _headerTests() {
  testWidgets('a resolved thread shows « Resolved »', (tester) async {
    await _pump(tester, _header(_Thread.resolved));

    expect(_resolvedMark, findsWidgets);
  });

  testWidgets('an open thread does not', (tester) async {
    await _pump(tester, _header(_Thread.open));

    expect(_resolvedMark, findsNothing);
  });

  testWidgets('the title and the root text stay', (tester) async {
    await _pump(tester, _header(_Thread.resolved));

    expect(find.text('Thread'), findsOneWidget);
    expect(find.text('Lunch on Friday?'), findsOneWidget);
  });

  testWidgets('in the app locale, its own word for « Resolved »', (
    tester,
  ) async {
    await _expectMarkInAppLocale(tester, _header(_Thread.resolved));
  });
}

void _cardTests() {
  testWidgets('a resolved thread says « Resolved » on its card', (
    tester,
  ) async {
    await _pump(tester, _card(_Thread.resolved));

    expect(_resolvedMark, findsWidgets);
  });

  testWidgets('the card of an open thread does not', (tester) async {
    await _pump(tester, _card(_Thread.open));

    expect(_resolvedMark, findsNothing);
  });

  testWidgets('the card still says how many messages', (tester) async {
    await _pump(tester, _card(_Thread.resolved));

    expect(find.bySemanticsLabel(RegExp('3 messages')), findsOneWidget);
  });

  testWidgets('the card says it in the app locale', (tester) async {
    await _expectMarkInAppLocale(tester, _card(_Thread.resolved));
  });
}
