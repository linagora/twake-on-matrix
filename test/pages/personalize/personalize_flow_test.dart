import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/personalize/personalize_flow.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';
import 'package:twake_chat/providers/personalization/personalize_steps_controller.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';
import 'package:twake_chat/utils/famedlysdk_store.provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../utils/option_card_semantics.dart';

// How the flow draws a step (cards, one big preview with a toggle, …) is not
// decided: these specs reach a choice only through its key, put on whatever
// control selects it, and never pin a layout.

const _counter = ValueKey<String>('personalize-step-counter');
const _next = ValueKey<String>('personalize-next');
const _back = ValueKey<String>('personalize-back');
const _done = ValueKey<String>('personalize-done');
const _more = ValueKey<String>('personalize-more');
const _close = ValueKey<String>('personalize-close');

/// A phone (below 905 px, `ResponsiveUtils.isMobile`) and a wide screen.
const _phone = Size(390, 844);
const _wide = Size(1200, 900);

/// The key of the control that selects [choice] in the step [stepId].
ValueKey<String> _option(String stepId, String choice) =>
    ValueKey<String>('option-$stepId-$choice');

/// What the user sees of each step: its choices in the order shown, the
/// default (the first one unless said), where the choice is stored and a
/// choice that is not the default.
class _Step {
  const _Step(
    this.step,
    this.choices, {
    required this.storeKey,
    this.byDefault,
  });

  final PersonalizeStep step;
  final List<String> choices;
  final String storeKey;
  final String? byDefault;

  String get id => step.id;
  String get defaultChoice => byDefault ?? choices.first;
  String get other => choices.lastWhere((choice) => choice != defaultChoice);
  ValueKey<String> get defaultKey => _option(id, defaultChoice);
  ValueKey<String> get otherKey => _option(id, other);
  List<ValueKey<String>> get keys => [
    for (final choice in choices) _option(id, choice),
  ];
}

const _steps = [
  _Step(PersonalizeStep.density, [
    'comfortable',
    'compact',
  ], storeKey: SettingKeys.chatListDensity),
  _Step(PersonalizeStep.order, [
    'recent',
    'sections',
  ], storeKey: SettingKeys.roomOrder),
  _Step(PersonalizeStep.seenStyle, [
    'ticks',
    'avatars',
    'names',
  ], storeKey: SettingKeys.seenStyle),
  // « compact » (the Modern composer) is shown first; « classic », today's
  // bar, is the default.
  _Step(
    PersonalizeStep.composer,
    ['compact', 'classic'],
    storeKey: SettingKeys.composerStyle,
    byDefault: 'classic',
  ),
  _Step(PersonalizeStep.align, [
    'ownRight',
    'left',
  ], storeKey: SettingKeys.bubbleAlign),
];

_Step _of(PersonalizeStep step) => _steps.firstWhere((s) => s.step == step);

/// What a wide screen never asked is handed: the five steps.
const _wideAll = [
  PersonalizeStep.density,
  PersonalizeStep.order,
  PersonalizeStep.seenStyle,
  PersonalizeStep.composer,
  PersonalizeStep.align,
];
const _wideIds = ['density', 'order', 'seen-style', 'composer', 'align'];

/// What a phone never asked is handed: no composer, the phone keeps today's
/// input bar.
const _phoneAll = [
  PersonalizeStep.density,
  PersonalizeStep.order,
  PersonalizeStep.seenStyle,
  PersonalizeStep.align,
];
const _phoneIds = ['density', 'order', 'seen-style', 'align'];

/// What is under the flow, and where « More options » leads. The settings
/// pages of the app live right under `/rooms` (`/rooms/folders`, …).
const _chatList = 'the chat list';
const _settingsPersonalization = 'the personalization settings';
const _settingsPersonalizationLocation = '/rooms/personalization';

/// A chat open next to the chat list, at `/rooms/<room>` like in the app.
const _openChat = 'an open chat';
const _openChatLocation = '/rooms/room';

/// A device whose storage refuses every write.
class _FullDisk extends Store {
  @override
  Future<void> setItem(String key, String? value) async =>
      throw Exception('disk full');

  @override
  Future<bool> setItems(String key, List<String> values) async =>
      throw Exception('disk full');
}

/// The flow, opened full screen over the chat list (or over the page at
/// [at]), on a phone unless [size] says otherwise.
class _Flow {
  _Flow(this.tester);

  final WidgetTester tester;
  late final ProviderContainer container;

  Future<void> open(
    List<PersonalizeStep> steps, {
    Size size = _phone,
    Map<String, Object> stored = const {},
    Store? store,
    String at = '/rooms',
  }) async {
    SharedPreferences.setMockInitialValues(stored);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [if (store != null) storeProvider.overrideWithValue(store)],
    );
    Widget launcher(BuildContext context, String title) => Scaffold(
      body: Column(
        children: [
          Text(title),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => PersonalizeFlow(steps: steps),
              ),
            ),
            child: const Text('start'),
          ),
        ],
      ),
    );
    final router = GoRouter(
      initialLocation: at,
      errorBuilder: (_, state) =>
          Scaffold(body: Text('no such page: ${state.uri}')),
      routes: [
        GoRoute(
          path: '/rooms',
          builder: (context, _) => launcher(context, _chatList),
          routes: [
            GoRoute(
              path: 'personalization',
              builder: (_, _) =>
                  const Scaffold(body: Text(_settingsPersonalization)),
            ),
            GoRoute(
              path: 'room',
              builder: (context, _) => launcher(context, _openChat),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
        ),
      ),
    );
    await settle();
    await tester.tap(find.text('start'));
    await settle();
  }

  /// Lets the storage answer and the page transitions end. Not
  /// `pumpAndSettle`: a preview may animate for ever.
  Future<void> settle() async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> tap(Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pump();
    await tester.tap(find.byKey(key));
    await settle();
  }

  /// Next, [times] times.
  Future<void> forward(int times) async {
    for (var i = 0; i < times; i++) {
      await tap(_next);
    }
  }

  /// Walks [steps] from the first one: [check] on each, then Next, but on the
  /// last one.
  Future<void> walkThrough(
    List<PersonalizeStep> steps,
    void Function(int index, PersonalizeStep step) check,
  ) async {
    for (final (index, step) in steps.indexed) {
      check(index, step);
      if (index < steps.length - 1) await tap(_next);
    }
  }

  /// Walks [steps]: each one says « n / total » and shows its choices alone.
  /// Ends on the last step, with Done.
  Future<void> expectWalk(List<PersonalizeStep> steps) async {
    await walkThrough(steps, (index, step) {
      expect(counter, _saysStep(index + 1, steps.length), reason: step.id);
      expectShows(_of(step));
    });
    expect(find.byKey(_done), findsOneWidget);
  }

  /// Walks [steps]: on each one, the choice [chosen] names alone is chosen.
  Future<void> expectChosenOnEach(
    List<PersonalizeStep> steps,
    ValueKey<String> Function(_Step step) chosen,
  ) => walkThrough(steps, (_, step) {
    for (final key in _of(step).keys) {
      expect(isChosen(key), key == chosen(_of(step)), reason: '$key');
    }
  });

  /// The top of each of [labels] on the screen, in the order given.
  List<double> topsOf(List<String> labels) => [
    for (final label in labels) tester.getRect(find.text(label)).top,
  ];

  Future<void> systemBack() async {
    await tester.binding.handlePopRoute();
    await settle();
  }

  /// The words of the step counter.
  String get counter => find
      .descendant(
        of: find.byKey(_counter),
        matching: find.byType(Text),
        matchRoot: true,
      )
      .evaluate()
      .map((element) => element.widget as Text)
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .join(' ');

  bool isChosen(Key option) => isAnnouncedAsChosen(tester, find.byKey(option));

  DisplayPreferencesState get preferences =>
      container.read(displayPreferencesControllerProvider).requireValue;

  /// The name of the choice the app holds for [step] now.
  String current(PersonalizeStep step) => switch (step) {
    PersonalizeStep.density => preferences.density.name,
    PersonalizeStep.order => preferences.roomOrder.name,
    PersonalizeStep.seenStyle => preferences.seenStyle.name,
    PersonalizeStep.composer => preferences.composerStyle.name,
    PersonalizeStep.align => preferences.bubbleAlign.name,
  };

  /// The step ids the device remembers as seen.
  Future<List<Object?>> get seen async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(SettingKeys.personalizedSteps);
    return stored == null ? const [] : jsonDecode(stored) as List<Object?>;
  }

  /// Only the choices of [step] are on screen.
  void expectShows(_Step step) {
    for (final other in _steps) {
      for (final key in other.keys) {
        expect(
          find.byKey(key),
          other == step ? findsOneWidget : findsNothing,
          reason: '$key on the step ${step.id}',
        );
      }
    }
  }

  /// Nothing of the flow is left.
  void expectClosed() {
    for (final key in [
      _counter,
      _next,
      _back,
      _done,
      _more,
      _close,
      for (final step in _steps) ...step.keys,
    ]) {
      expect(find.byKey(key), findsNothing);
    }
  }

  void expectBackOnTheChatList() {
    expectClosed();
    expect(find.text(_chatList), findsOneWidget);
  }
}

/// « 1 / 4 », whatever the words around the two numbers.
Matcher _saysStep(int current, int total) =>
    matches(RegExp('^\\D*$current\\D+$total\\D*\$'));

/// The steps the app hands the flow at start, read from the device as the
/// app does it, for a screen of [size].
Future<List<PersonalizeStep>> _pendingAt(Size size) {
  final restarted = ProviderContainer.test(retry: (_, _) => null);
  return restarted
      .read(personalizeStepsControllerProvider.notifier)
      .pending(isWide: size.width >= 905);
}

final _en = lookupL10n(const Locale('en'));

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  _pendingAtStartTests();
  _phoneFlowTests();
  _phoneButtonsTests();
  _wideFlowTests();
  _fixedStepsTests();
  _choiceTests();
  _closingTests();
  _rememberingTests();
  _moreOptionsTests();
  _orderPreviewTests();
}

void _pendingAtStartTests() {
  group('the steps handed to the flow at start', () {
    testWidgets('a phone never asked: the four steps, no composer', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      expect(await _pendingAt(_phone), _phoneAll);
    });

    testWidgets('a wide screen never asked: the five steps, composer '
        'included', (tester) async {
      SharedPreferences.setMockInitialValues({});

      expect(await _pendingAt(_wide), _wideAll);
    });
  });
}

void _phoneFlowTests() {
  group('the personalization flow on a phone, one step at a time', () {
    testWidgets('a phone never asked: opens on the density, 1 of 4', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);

      expect(flow.counter, _saysStep(1, 4));
      flow.expectShows(_of(PersonalizeStep.density));
    });

    testWidgets('Next walks the four steps in order, and never shows the '
        'composer', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);

      await flow.expectWalk(_phoneAll);
    });

    testWidgets('a step added by a later release is asked alone: 1 of 1, Done '
        'at once', (tester) async {
      final flow = _Flow(tester);
      await flow.open(const [PersonalizeStep.seenStyle]);

      expect(flow.counter, _saysStep(1, 1));
      flow.expectShows(_of(PersonalizeStep.seenStyle));
      expect(find.byKey(_done), findsOneWidget);
      expect(find.byKey(_next), findsNothing);
      expect(find.byKey(_back), findsNothing);
    });

    testWidgets('with no step to ask, nothing is shown', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer.test(retry: (_, _) => null);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: const PersonalizeFlow(steps: []),
          ),
        ),
      );
      await tester.pump();

      _Flow(tester).expectClosed();
      expect(find.byType(Text), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('each step fits without an overflow, with larger text too', (
      tester,
    ) async {
      final flow = _Flow(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await flow.open(_phoneAll);

      await flow.walkThrough(
        _phoneAll,
        (_, step) => expect(tester.takeException(), isNull, reason: step.id),
      );
      expect(find.byKey(_done), findsOneWidget);
    });
  });
}

void _phoneButtonsTests() {
  group('the buttons of the flow on a phone', () {
    testWidgets('the first step offers Next, More options and Close, and no '
        'Back nor Done', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);

      for (final key in [_next, _more, _close]) {
        expect(find.byKey(key), findsOneWidget, reason: '$key');
      }
      for (final key in [_back, _done]) {
        expect(find.byKey(key), findsNothing, reason: '$key');
      }
    });

    testWidgets('a middle step offers Back and Next, not Done', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);

      await flow.forward(2);

      expect(find.byKey(_back), findsOneWidget);
      expect(find.byKey(_next), findsOneWidget);
      expect(find.byKey(_done), findsNothing);
    });

    testWidgets('the last step offers Done instead of Next, and Back', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);

      await flow.forward(3);

      expect(flow.counter, _saysStep(4, 4));
      flow.expectShows(_of(PersonalizeStep.align));
      for (final key in [_done, _back, _more, _close]) {
        expect(find.byKey(key), findsOneWidget, reason: '$key');
      }
      expect(find.byKey(_next), findsNothing);
    });

    testWidgets('Back returns to the previous step', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);
      await flow.forward(2);

      await flow.tap(_back);

      expect(flow.counter, _saysStep(2, 4));
      flow.expectShows(_of(PersonalizeStep.order));
    });

    testWidgets('Back down to the first step: no Back any more', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);
      await flow.forward(1);

      await flow.tap(_back);

      expect(flow.counter, _saysStep(1, 4));
      flow.expectShows(_of(PersonalizeStep.density));
      expect(find.byKey(_back), findsNothing);
      expect(find.byKey(_next), findsOneWidget);
    });
  });
}

void _wideFlowTests() {
  group('the personalization flow on a wide screen', () {
    testWidgets('Next walks the five steps in order, the composer between '
        'the seen style and the align', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_wideAll, size: _wide);

      await flow.expectWalk(_wideAll);
    });

    testWidgets('the composer offers « compact » and « classic », « classic » '
        'chosen on arrival', (tester) async {
      final flow = _Flow(tester);
      await flow.open(const [PersonalizeStep.composer], size: _wide);

      expect(flow.counter, _saysStep(1, 1));
      expect(find.byKey(_option('composer', 'compact')), findsOneWidget);
      expect(find.byKey(_option('composer', 'classic')), findsOneWidget);
      expect(flow.isChosen(_option('composer', 'classic')), isTrue);
      expect(flow.isChosen(_option('composer', 'compact')), isFalse);
    });

    testWidgets('the composer closed without a choice keeps the classic bar', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(const [PersonalizeStep.composer], size: _wide);

      await flow.tap(_close);

      expect(flow.preferences.composerStyle, ComposerStyle.classic);
    });

    testWidgets('three steps still to ask: 1 of 3, then the three in order', (
      tester,
    ) async {
      final flow = _Flow(tester);
      final three = _wideAll.skip(2).toList();
      await flow.open(three, size: _wide);

      await flow.expectWalk(three);
    });

    testWidgets('each step fits without an overflow, with larger text too', (
      tester,
    ) async {
      final flow = _Flow(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await flow.open(_wideAll, size: _wide);

      await flow.walkThrough(
        _wideAll,
        (_, step) => expect(tester.takeException(), isNull, reason: step.id),
      );
      expect(find.byKey(_done), findsOneWidget);
    });
  });
}

void _fixedStepsTests() {
  group('the steps of an open flow are fixed', () {
    testWidgets('marking them seen elsewhere does not take them away', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);

      flow.container
          .read(personalizeStepsControllerProvider.notifier)
          .markSeen(PersonalizeStep.values);
      await flow.settle();

      expect(flow.counter, _saysStep(1, 4));
      flow.expectShows(_of(PersonalizeStep.density));
      await flow.tap(_next);
      expect(flow.counter, _saysStep(2, 4));
      flow.expectShows(_of(PersonalizeStep.order));
    });

    testWidgets('a choice does not move the flow nor change its steps', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);

      await flow.tap(_option('density', 'compact'));

      expect(flow.counter, _saysStep(1, 4));
      flow.expectShows(_of(PersonalizeStep.density));
      expect(find.byKey(_next), findsOneWidget);
    });
  });
}

void _choiceTests() {
  group('a choice in the flow', () {
    testWidgets('a device never asked shows the default of each step as '
        'chosen', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_wideAll, size: _wide);

      await flow.expectChosenOnEach(_wideAll, (step) => step.defaultKey);
    });

    testWidgets('each step shows what the device stored as chosen', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(
        _wideAll,
        size: _wide,
        stored: {for (final step in _steps) step.storeKey: step.other},
      );

      await flow.expectChosenOnEach(_wideAll, (step) => step.otherKey);
    });

    for (final (index, step) in _wideAll.map(_of).indexed) {
      testWidgets('of ${step.id}: applies at once and is kept on the device', (
        tester,
      ) async {
        final flow = _Flow(tester);
        await flow.open(_wideAll, size: _wide);
        await flow.forward(index);

        await flow.tap(_option(step.id, step.other));

        expect(flow.current(step.step), step.other);
        expect(flow.isChosen(_option(step.id, step.other)), isTrue);
        expect(flow.isChosen(step.defaultKey), isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(step.storeKey), step.other);
      });
    }

    testWidgets('of a middle choice of three: that one alone is chosen', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);
      await flow.forward(2);

      await flow.tap(_option('seen-style', 'avatars'));

      expect(flow.preferences.seenStyle, SeenStyle.avatars);
      for (final choice in ['ticks', 'avatars', 'names']) {
        expect(
          flow.isChosen(_option('seen-style', choice)),
          choice == 'avatars',
          reason: choice,
        );
      }
    });

    testWidgets('is still there after Next then Back', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);
      await flow.tap(_option('density', 'compact'));

      await flow.tap(_next);
      await flow.tap(_back);

      expect(flow.isChosen(_option('density', 'compact')), isTrue);
      expect(flow.preferences.density, ChatListDensity.compact);
    });

    testWidgets('stays when the flow is closed without Done', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);
      await flow.tap(_option('density', 'compact'));

      await flow.tap(_close);

      expect(flow.preferences.density, ChatListDensity.compact);
    });
  });
}

void _closingTests() {
  group('closing the flow', () {
    testWidgets('while it is open, no step is remembered as seen', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);
      await flow.tap(_option('density', 'compact'));
      await flow.forward(3);

      expect(await flow.seen, isEmpty);
    });

    testWidgets('Done on a phone remembers the four steps it showed, not the '
        'composer', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);
      await flow.forward(3);

      await flow.tap(_done);

      flow.expectBackOnTheChatList();
      expect(await flow.seen, unorderedEquals(_phoneIds));
    });

    testWidgets('Done on a wide screen remembers the five steps', (
      tester,
    ) async {
      final flow = _Flow(tester);
      await flow.open(_wideAll, size: _wide);
      await flow.forward(4);

      await flow.tap(_done);

      flow.expectBackOnTheChatList();
      expect(await flow.seen, unorderedEquals(_wideIds));
    });

    for (final (name, forward, close) in [
      ('the close button on the first step', 0, _ByClose.button),
      ('the close button on a middle step', 2, _ByClose.button),
      ('the system back on the first step', 0, _ByClose.systemBack),
      (
        'the system back on a later step, it is not Back',
        2,
        _ByClose.systemBack,
      ),
    ]) {
      testWidgets('$name closes it and remembers every step shown, the ones '
          'not reached too', (tester) async {
        final flow = _Flow(tester);
        await flow.open(_phoneAll);
        await flow.forward(forward);

        await switch (close) {
          _ByClose.button => flow.tap(_close),
          _ByClose.systemBack => flow.systemBack(),
        };

        flow.expectBackOnTheChatList();
        expect(await flow.seen, unorderedEquals(_phoneIds));
      });
    }

    testWidgets('a storage that refuses the write does not keep the user in '
        'the flow', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll, store: _FullDisk());
      await flow.forward(3);

      await flow.tap(_done);

      flow.expectBackOnTheChatList();
      expect(tester.takeException(), isNull);
    });
  });
}

/// The two ways out of the flow that are not Done.
enum _ByClose { button, systemBack }

void _rememberingTests() {
  group('what a closed flow remembers', () {
    testWidgets('a flow of three steps remembers those three, and keeps what '
        'was seen before', (tester) async {
      final flow = _Flow(tester);
      await flow.open(
        _wideAll.skip(2).toList(),
        size: _wide,
        stored: {SettingKeys.personalizedSteps: '["density","order"]'},
      );

      await flow.tap(_close);

      expect(await flow.seen, unorderedEquals(_wideIds));
    });

    testWidgets('adds to what the device had seen, ids of a newer version '
        'included, each id once', (tester) async {
      final flow = _Flow(tester);
      await flow.open(
        const [PersonalizeStep.align],
        stored: {SettingKeys.personalizedSteps: '["wallpaper","density"]'},
      );

      await flow.tap(_done);

      expect(
        await flow.seen,
        unorderedEquals(['wallpaper', 'density', 'align']),
      );
    });

    testWidgets('closed on a phone: the phone asks nothing at the next start, '
        'a tablet asks the composer alone', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);

      await flow.tap(_close);

      expect(await _pendingAt(_phone), isEmpty);
      expect(await _pendingAt(_wide), [PersonalizeStep.composer]);
    });

    testWidgets('closed on a wide screen: nothing is asked at the next start, '
        'on a phone either', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_wideAll, size: _wide);

      await flow.tap(_close);

      expect(await _pendingAt(_wide), isEmpty);
      expect(await _pendingAt(_phone), isEmpty);
    });
  });
}

void _moreOptionsTests() {
  group('« More options »', () {
    testWidgets('closes the flow, remembers every step shown and opens the '
        'personalization settings', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);

      await flow.tap(_more);

      flow.expectClosed();
      expect(find.text(_settingsPersonalization), findsOneWidget);
      expect(
        find.text('no such page: $_settingsPersonalizationLocation'),
        findsNothing,
      );
      expect(await flow.seen, unorderedEquals(_phoneIds));
    });

    testWidgets('from the last step too', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);
      await flow.forward(3);

      await flow.tap(_more);

      flow.expectClosed();
      expect(find.text(_settingsPersonalization), findsOneWidget);
      expect(await flow.seen, unorderedEquals(_phoneIds));
    });

    testWidgets('back from the personalization settings returns to the chat '
        'list', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll);
      await flow.tap(_more);

      await flow.systemBack();

      expect(find.text(_settingsPersonalization), findsNothing);
      expect(find.text(_chatList), findsOneWidget);
    });

    testWidgets('opened over a chat: back from the personalization settings '
        'returns to that chat, not to the chat list', (tester) async {
      final flow = _Flow(tester);
      await flow.open(_phoneAll, at: _openChatLocation);
      // Under the flow: the chat the user was in.
      expect(find.text(_openChat, skipOffstage: false), findsOneWidget);
      await flow.tap(_more);
      expect(find.text(_settingsPersonalization), findsOneWidget);

      await flow.systemBack();

      expect(find.text(_settingsPersonalization), findsNothing);
      expect(find.text(_openChat), findsOneWidget);
    });
  });
}

void _orderPreviewTests() {
  group('the drawing of the order step', () {
    testWidgets('« sections »: unread, then groups, then direct chats, as the '
        'chat list orders them', (tester) async {
      final flow = _Flow(tester);
      await flow.open(const [PersonalizeStep.order]);

      await flow.tap(_option('order', 'sections'));

      final tops = flow.topsOf([_en.unread, _en.groups, _en.directChats]);
      expect(tops, [...tops]..sort(), reason: 'unread, groups, directs');
      expect(tops.toSet().length, tops.length);
    });

    testWidgets('« recent »: no section title', (tester) async {
      final flow = _Flow(tester);
      await flow.open(const [PersonalizeStep.order]);

      for (final title in [_en.unread, _en.groups, _en.directChats]) {
        expect(find.text(title), findsNothing, reason: title);
      }
    });
  });
}
