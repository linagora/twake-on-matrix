import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/personalize/personalize_launch.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../providers/personalization/fake_display_preferences_repository.dart';

// The trigger the chat list runs at start (ChatList._askPersonalization):
// once per run of the app, with the steps pending for the width of the
// screen. The chat list runs it once its first sync is done; these specs run
// it once their own sync is done, as the app does (review of #3844).
//
// The flow never opens over a chat: after a start from a notification or a
// share, the chat is open on top of the list; the flow waits until the user
// is back on the chat list, then opens once.

const _counter = ValueKey<String>('personalize-step-counter');
const _close = ValueKey<String>('personalize-close');

const _phone = Size(390, 844);
const _wide = Size(1200, 900);

const _aChat = 'a chat';

const _allIds = {'density', 'order', 'seen-style', 'composer', 'align'};

/// The chat list of a started app, its first sync done, over a device that
/// saw [seen], on a screen of [size]. [launch] runs the trigger, as the chat
/// list does.
class _ChatList {
  _ChatList(this.tester);

  final WidgetTester tester;
  late FakeDisplayPreferencesRepository storage;
  late BuildContext _context;

  Future<void> show({Set<String> seen = const {}, Size size = _phone}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    storage = FakeDisplayPreferencesRepository(seen: seen);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        displayPreferencesRepositoryProvider.overrideWithValue(storage),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        key: UniqueKey(),
        container: container,
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                _context = context;
                return const Text('the chat list');
              },
            ),
          ),
        ),
      ),
    );
  }

  void launch() => unawaited(PersonalizeLaunch.afterFirstSync(_context));

  /// A chat opened on top of the list, as a notification or a share does.
  Future<void> openChat() async {
    unawaited(
      Navigator.of(_context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text(_aChat)),
        ),
      ),
    );
    await settle();
  }

  /// Back from the chat to the list.
  Future<void> back() async {
    Navigator.of(_context).pop();
    await settle();
  }

  /// Lets the storage answer and the page transitions end. Not
  /// `pumpAndSettle`: a preview may animate for ever.
  Future<void> settle() async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  bool get flowIsOpen => find.byKey(_counter).evaluate().isNotEmpty;

  /// The words of the step counter.
  String get counter => (tester.widget<Text>(
    find.descendant(
      of: find.byKey(_counter),
      matching: find.byType(Text),
      matchRoot: true,
    ),
  )).data!;
}

/// « 1 / 4 », whatever the words around the two numbers.
Matcher _saysStep(int current, int total) =>
    matches(RegExp('^\\D*$current\\D+$total\\D*\$'));

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  setUp(PersonalizeLaunch.resetForTesting);

  _whenAndWhatTests();
  _onceOnlyTests();
  _overAChatTests();
  _resizedWhileLoadingTests();
}

// Review of #3844 (CodeRabbit): the width that counts is the one of the
// screen when the flow opens, not when the storage was asked.
void _resizedWhileLoadingTests() {
  group('the screen turned from wide to phone before the storage answered', () {
    testWidgets('the flow opens with the four phone steps, no composer', (
      tester,
    ) async {
      final chatList = _ChatList(tester);
      await chatList.show(size: _wide);
      chatList.storage.holdLoads();
      chatList.launch();

      tester.view.physicalSize = _phone;
      await tester.pump();
      chatList.storage.answer();
      await chatList.settle();

      expect(chatList.flowIsOpen, isTrue);
      expect(chatList.counter, _saysStep(1, 4));
    });

    testWidgets('a chat on top: waits for the chat list, then the four phone '
        'steps', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show(size: _wide);
      await chatList.openChat();
      chatList.storage.holdLoads();
      chatList.launch();

      tester.view.physicalSize = _phone;
      await tester.pump();
      chatList.storage.answer();
      await chatList.settle();

      expect(chatList.flowIsOpen, isFalse);
      expect(find.text(_aChat), findsOneWidget);

      await chatList.back();

      expect(chatList.counter, _saysStep(1, 4));
    });
  });
}

void _whenAndWhatTests() {
  group('the personalization asked at start', () {
    testWidgets('opens over the chat list', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show();

      chatList.launch();
      await chatList.settle();

      expect(chatList.flowIsOpen, isTrue);
    });

    testWidgets('a phone: the four steps, no composer', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show();

      chatList.launch();
      await chatList.settle();

      expect(chatList.counter, _saysStep(1, 4));
    });

    testWidgets('a wide screen: the five steps, composer included', (
      tester,
    ) async {
      final chatList = _ChatList(tester);
      await chatList.show(size: _wide);

      chatList.launch();
      await chatList.settle();

      expect(chatList.counter, _saysStep(1, 5));
    });

    testWidgets('a phone that saw its four steps: nothing opens, though a '
        'wide screen would ask the composer', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show(seen: _allIds.difference({'composer'}));

      chatList.launch();
      await chatList.settle();

      expect(chatList.flowIsOpen, isFalse);
      expect(find.text('the chat list'), findsOneWidget);
    });

    testWidgets('a device that saw every step: nothing opens', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show(seen: _allIds, size: _wide);

      chatList.launch();
      await chatList.settle();

      expect(chatList.flowIsOpen, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}

void _onceOnlyTests() {
  group('the personalization asked at start', () {
    testWidgets('asked twice in the same run: one flow only', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show();

      chatList
        ..launch()
        ..launch();
      await chatList.settle();
      expect(find.byKey(_counter), findsOneWidget);

      await tester.tap(find.byKey(_close));
      await chatList.settle();
      expect(chatList.flowIsOpen, isFalse);
    });

    testWidgets('once per run of the app: a chat list built again, on a '
        'device with steps still to ask, does not open it again', (
      tester,
    ) async {
      final first = _ChatList(tester);
      await first.show();
      first.launch();
      await first.settle();
      await tester.tap(find.byKey(_close));
      await first.settle();

      // Another account, or the chat list built again: steps are pending.
      final again = _ChatList(tester);
      await again.show();
      again.launch();
      await again.settle();

      expect(again.flowIsOpen, isFalse);
    });

    testWidgets('the chat list gone before the storage answers: nothing '
        'opens, no error', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show();
      chatList.storage.holdLoads();
      chatList.launch();

      await tester.pumpWidget(const SizedBox.shrink());
      chatList.storage.answer();
      await chatList.settle();

      expect(chatList.flowIsOpen, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}

void _overAChatTests() {
  group(
    'the personalization asked at start, a chat open on top of the list',
    () {
      testWidgets('does not open over the chat', (tester) async {
        final chatList = _ChatList(tester);
        await chatList.show();
        await chatList.openChat();

        chatList.launch();
        await chatList.settle();

        expect(chatList.flowIsOpen, isFalse);
        expect(find.text(_aChat), findsOneWidget);
      });

      testWidgets('opens once the user is back on the chat list', (
        tester,
      ) async {
        final chatList = _ChatList(tester);
        await chatList.show();
        await chatList.openChat();
        chatList.launch();
        await chatList.settle();

        await chatList.back();

        expect(find.byKey(_counter), findsOneWidget);
        expect(chatList.counter, _saysStep(1, 4));
      });

      testWidgets('once only: closed, then a chat opened and left again, it '
          'does not come back', (tester) async {
        final chatList = _ChatList(tester);
        await chatList.show();
        await chatList.openChat();
        chatList.launch();
        await chatList.settle();
        await chatList.back();
        await tester.tap(find.byKey(_close));
        await chatList.settle();

        await chatList.openChat();
        await chatList.back();

        expect(chatList.flowIsOpen, isFalse);
        expect(find.text('the chat list'), findsOneWidget);
      });
    },
  );
}
