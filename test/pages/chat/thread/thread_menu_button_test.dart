import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/data/repository/thread/thread_prefs_repository.provider.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/thread/thread_menu_button.dart';

import '../../../domain/thread/fake_thread_prefs_repository.dart';
import 'pseudo_l10n.dart';

/// THR-M-07 and THR-M-08, labels of § 8: the « ⋮ » menu of the thread
/// header. « Follow the thread » / « Unfollow the thread »; when followed,
/// « Mute the thread » / « Unmute the thread »; to who may set the resolved
/// state only, « Mark as resolved » / « Reopen the thread ». A change that
/// fails says « The thread could not be changed. » and the menu stays as it
/// was.
void main() {
  setUp(() => _repository = FakeThreadPrefsRepository());
  tearDown(() => _repository.close());

  group('the items', _itemTests);
  group('choosing an item', _choiceTests);
  group('while a change is being saved', _savingTests);
  group('the thread cannot be read', _watchFailureTests);
  group('in the app locale', _appLocaleTests);
}

late FakeThreadPrefsRepository _repository;

const _globalDelegates = <LocalizationsDelegate<Object>>[
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

const _english = <LocalizationsDelegate<Object>>[
  L10n.delegate,
  ..._globalDelegates,
];

/// The labels are Weblate's for every locale but English: the pseudo
/// locale marks each one, so a label written in the code shows unmarked.
const _pseudoStrings = <LocalizationsDelegate<Object>>[
  PseudoL10nDelegate(),
  ..._globalDelegates,
];

/// The ProviderScope is the root handed to `pumpWidget`, as in the app.
Future<void> _pumpApp(
  WidgetTester tester,
  Widget home, {
  List<LocalizationsDelegate<Object>> strings = _english,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [threadPrefsRepositoryProvider.overrideWithValue(_repository)],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: strings,
      supportedLocales: LocalizationService.supportedLocales,
      home: home,
    ),
  ),
);

Widget _threadScreen() => Scaffold(
  appBar: AppBar(actions: const [ThreadMenuButton(thread: lunchThread)]),
);

/// The account answers [status] to the screen on show.
Future<void> _accountSays(WidgetTester tester, ThreadStatus status) async {
  await tester.pump();
  _repository.show(status);
  await tester.pumpAndSettle();
}

Future<void> _pumpMenu(
  WidgetTester tester,
  ThreadStatus status, {
  List<LocalizationsDelegate<Object>> strings = _english,
}) async {
  await _pumpApp(tester, _threadScreen(), strings: strings);
  await _accountSays(tester, status);
}

/// The thread screen pushed over the room, as the app opens it.
Future<void> _pumpPushedMenu(WidgetTester tester, ThreadStatus status) async {
  await _pumpApp(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => _threadScreen())),
          child: const Text('Open the thread'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open the thread'));
  await tester.pumpAndSettle();
  await _accountSays(tester, status);
}

/// Back to the room: the thread screen goes.
Future<void> _leaveTheThread(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More'));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String item) async {
  await _openMenu(tester);
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

/// The menu, opened on [status], offers [shown] and none of [hidden].
Future<void> _expectItems(
  WidgetTester tester,
  ThreadStatus status, {
  required List<String> shown,
  List<String> hidden = const [],
}) async {
  await _pumpMenu(tester, status);
  await _openMenu(tester);
  for (final item in shown) {
    expect(find.text(item), findsOneWidget, reason: item);
  }
  for (final item in hidden) {
    expect(find.text(item), findsNothing, reason: item);
  }
}

void _itemTests() {
  testWidgets('a thread not followed can be followed, not muted', (
    tester,
  ) async {
    await _expectItems(
      tester,
      statusOf(notFollowed),
      shown: ['Follow the thread'],
      hidden: ['Unfollow the thread', 'Mute the thread', 'Unmute the thread'],
    );
  });

  testWidgets('a followed thread can be unfollowed or muted', (tester) async {
    await _expectItems(
      tester,
      statusOf(followed),
      shown: ['Unfollow the thread', 'Mute the thread'],
      hidden: ['Follow the thread', 'Unmute the thread'],
    );
  });

  testWidgets('a muted thread can be unmuted or unfollowed', (tester) async {
    await _expectItems(
      tester,
      statusOf(muted),
      shown: ['Unfollow the thread', 'Unmute the thread'],
      hidden: ['Mute the thread'],
    );
  });

  testWidgets('an open thread can be marked as resolved', (tester) async {
    await _expectItems(
      tester,
      statusOf(followed),
      shown: ['Mark as resolved'],
      hidden: ['Reopen the thread'],
    );
  });

  testWidgets('a resolved thread can be reopened', (tester) async {
    await _expectItems(
      tester,
      statusOf(followed, isResolved: true),
      shown: ['Reopen the thread'],
      hidden: ['Mark as resolved'],
    );
  });

  testWidgets('who may not set the resolved state sees neither', (
    tester,
  ) async {
    await _expectItems(
      tester,
      withoutResolve(followed),
      shown: ['Unfollow the thread'],
      hidden: ['Mark as resolved', 'Reopen the thread'],
    );
  });
}

void _choiceTests() {
  testWidgets('following: the next time, the menu offers to unfollow', (
    tester,
  ) async {
    await _pumpMenu(tester, statusOf(notFollowed));

    await _choose(tester, 'Follow the thread');

    expect(_repository.changes, [
      const PrefSaved(lunchThread, ThreadPref.follow),
    ]);
    await _openMenu(tester);
    expect(find.text('Unfollow the thread'), findsOneWidget);
  });

  testWidgets('resolving: the next time, the menu offers to reopen', (
    tester,
  ) async {
    await _pumpMenu(tester, statusOf(followed));

    await _choose(tester, 'Mark as resolved');

    expect(_repository.changes, [
      const ResolvedSaved(lunchThread, resolved: true),
    ]);
    await _openMenu(tester);
    expect(find.text('Reopen the thread'), findsOneWidget);
  });

  testWidgets('a change that fails is told, and the menu stays as it was', (
    tester,
  ) async {
    _repository.isDown = true;
    await _pumpMenu(tester, statusOf(followed));

    await _choose(tester, 'Mute the thread');

    expect(find.text('The thread could not be changed.'), findsOneWidget);
    await _openMenu(tester);
    expect(find.text('Mute the thread'), findsOneWidget);
    expect(find.text('Unmute the thread'), findsNothing);
  });

  testWidgets('closing the menu without choosing changes nothing', (
    tester,
  ) async {
    await _pumpMenu(tester, statusOf(followed));
    await _openMenu(tester);

    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    expect(find.text('Mute the thread'), findsNothing);
    expect(_repository.changes, isEmpty);
  });
}

/// The thread screen opens, what the account says of the thread cannot be
/// read, and the user opens the « ⋮ » menu.
Future<void> _openMenuOfUnreadableThread(
  WidgetTester tester, {
  List<LocalizationsDelegate<Object>> strings = _english,
}) async {
  await _pumpApp(tester, _threadScreen(), strings: strings);
  await tester.pump();
  _repository.failWatching();
  await tester.pumpAndSettle();
  await _openMenu(tester);
}

/// Else the menu stays disabled without a word: the user is told.
void _watchFailureTests() {
  testWidgets('the menu tells the failure', (tester) async {
    await _openMenuOfUnreadableThread(tester);

    expect(find.text('Oops, something went wrong…'), findsOneWidget);
  });

  testWidgets('in the app locale', (tester) async {
    await _openMenuOfUnreadableThread(tester, strings: _pseudoStrings);

    expect(find.text(pseudo('Oops, something went wrong…')), findsOneWidget);
  });
}

/// The server takes its time: what the user may do meanwhile.
void _savingTests() {
  // Made in the test: a completer of setUp would resume the save outside
  // the fake clock of the widget test.
  void serverIsSlow() => _repository.slowServer = Completer();

  testWidgets('the menu does not open: no second choice meanwhile', (
    tester,
  ) async {
    serverIsSlow();
    await _pumpMenu(tester, statusOf(followed));
    await _choose(tester, 'Mute the thread');

    await _openMenu(tester);

    expect(find.text('Unfollow the thread'), findsNothing);
    expect(_repository.changes, [
      const PrefSaved(lunchThread, ThreadPref.mute),
    ]);
  });

  testWidgets('once saved, the menu opens on the new state', (tester) async {
    serverIsSlow();
    await _pumpMenu(tester, statusOf(followed));
    await _choose(tester, 'Mute the thread');

    _repository.slowServer!.complete();
    await tester.pumpAndSettle();
    await _openMenu(tester);

    expect(find.text('Unmute the thread'), findsOneWidget);
  });

  for (final refused in [false, true]) {
    final outcome = refused ? 'refused' : 'saved';
    testWidgets('leaving the thread before the change is $outcome throws '
        'nothing', (tester) async {
      serverIsSlow();
      _repository.isDown = refused;
      await _pumpPushedMenu(tester, statusOf(followed));
      await _choose(tester, 'Mute the thread');

      await _leaveTheThread(tester);
      _repository.slowServer!.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Open the thread'), findsOneWidget);
    });
  }

  /// Maintainer decision of 11/11: THR-M-07 and THR-M-08 tell every failure,
  /// also one that comes once the user is back in the room.
  testWidgets('refused after leaving the thread: the room tells the '
      'failure', (tester) async {
    serverIsSlow();
    _repository.isDown = true;
    await _pumpPushedMenu(tester, statusOf(followed));
    await _choose(tester, 'Mute the thread');

    await _leaveTheThread(tester);
    _repository.slowServer!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Open the thread'), findsOneWidget);
    expect(find.text('The thread could not be changed.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// The labels are Weblate's for every locale but English, which may not
/// have them yet: the pseudo locale marks each one, so a label written in
/// the code would show unmarked.
void _appLocaleTests() {
  Future<void> openMenu(WidgetTester tester, ThreadStatus status) async {
    await _pumpMenu(tester, status, strings: _pseudoStrings);
    await _openMenu(tester);
  }

  testWidgets('a thread not followed offers to follow it', (tester) async {
    await openMenu(tester, statusOf(notFollowed));

    expect(find.text(pseudo('Follow the thread')), findsOneWidget);
  });

  testWidgets('a followed open thread offers unfollow, mute and resolve', (
    tester,
  ) async {
    await openMenu(tester, statusOf(followed));

    expect(find.text(pseudo('Unfollow the thread')), findsOneWidget);
    expect(find.text(pseudo('Mute the thread')), findsOneWidget);
    expect(find.text(pseudo('Mark as resolved')), findsOneWidget);
  });

  testWidgets('a muted resolved thread offers unmute and reopen', (
    tester,
  ) async {
    await openMenu(tester, statusOf(muted, isResolved: true));

    expect(find.text(pseudo('Unmute the thread')), findsOneWidget);
    expect(find.text(pseudo('Reopen the thread')), findsOneWidget);
  });

  testWidgets('a failure is told', (tester) async {
    _repository.isDown = true;
    await openMenu(tester, statusOf(notFollowed));

    await tester.tap(find.text(pseudo('Follow the thread')));
    await tester.pumpAndSettle();

    expect(
      find.text(pseudo('The thread could not be changed.')),
      findsOneWidget,
    );
  });
}
