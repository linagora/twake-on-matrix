import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/personalize/personalize_launch.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../providers/personalization/fake_display_preferences_repository.dart';

// The trigger the chat list runs at start (ChatList._askPersonalization):
// once per run of the app, after the first sync, with the steps pending for
// the width of the screen. The chat list hands it the first sync; these
// specs hand it one they complete themselves.

const _counter = ValueKey<String>('personalize-step-counter');
const _close = ValueKey<String>('personalize-close');

const _phone = Size(390, 844);
const _wide = Size(1200, 900);

const _allIds = {'density', 'order', 'seen-style', 'composer', 'align'};

/// The chat list of a started app, over a device that saw [seen], on a
/// screen of [size]. [launch] runs the trigger, as the chat list does.
class _ChatList {
  _ChatList(this.tester);

  final WidgetTester tester;
  final firstSync = Completer<void>();
  late BuildContext _context;

  Future<void> show({Set<String> seen = const {}, Size size = _phone}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        displayPreferencesRepositoryProvider.overrideWithValue(
          FakeDisplayPreferencesRepository(seen: seen),
        ),
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

  void launch() => unawaited(
    PersonalizeLaunch.afterFirstSync(_context, firstSync: firstSync.future),
  );

  Future<void> sync() async {
    if (!firstSync.isCompleted) firstSync.complete();
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

  group('the personalization asked at start', () {
    testWidgets('waits for the first sync, then opens over the chat list', (
      tester,
    ) async {
      final chatList = _ChatList(tester);
      await chatList.show();

      chatList.launch();
      await chatList.settle();
      expect(chatList.flowIsOpen, isFalse, reason: 'before the first sync');

      await chatList.sync();
      expect(chatList.flowIsOpen, isTrue);
    });

    testWidgets('a phone: the four steps, no composer', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show();

      chatList.launch();
      await chatList.sync();

      expect(chatList.counter, _saysStep(1, 4));
    });

    testWidgets('a wide screen: the five steps, composer included', (
      tester,
    ) async {
      final chatList = _ChatList(tester);
      await chatList.show(size: _wide);

      chatList.launch();
      await chatList.sync();

      expect(chatList.counter, _saysStep(1, 5));
    });

    testWidgets('a phone that saw its four steps: nothing opens, though a '
        'wide screen would ask the composer', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show(seen: _allIds.difference({'composer'}));

      chatList.launch();
      await chatList.sync();

      expect(chatList.flowIsOpen, isFalse);
      expect(find.text('the chat list'), findsOneWidget);
    });

    testWidgets('a device that saw every step: nothing opens', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show(seen: _allIds, size: _wide);

      chatList.launch();
      await chatList.sync();

      expect(chatList.flowIsOpen, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('asked twice in the same run: one flow only', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show();

      chatList
        ..launch()
        ..launch();
      await chatList.sync();
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
      await first.sync();
      await tester.tap(find.byKey(_close));
      await first.settle();

      // Another account, or the chat list built again: steps are pending.
      final again = _ChatList(tester);
      await again.show();
      again.launch();
      await again.sync();

      expect(again.flowIsOpen, isFalse);
    });

    testWidgets('the chat list gone before the first sync: nothing opens, no '
        'error', (tester) async {
      final chatList = _ChatList(tester);
      await chatList.show();
      chatList.launch();

      await tester.pumpWidget(const SizedBox.shrink());
      await chatList.sync();

      expect(chatList.flowIsOpen, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
