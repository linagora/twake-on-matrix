import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_personalization/settings_personalization.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../../utils/option_card_semantics.dart';

ValueKey<String> _card(String stepId, String choice) =>
    ValueKey<String>('option-$stepId-$choice');

/// A phone (below 905 px, `ResponsiveUtils.isMobile`) and a wide screen.
/// Tall enough to hold every option: what a scroll reveals is not what these
/// specs are about.
const _phone = Size(390, 6000);
const _wide = Size(1200, 6000);

/// Each option of the screen: its step id, its choices in the order shown,
/// the default (the first one unless said), where it is stored and how its
/// cards are laid out on a phone.
class _Section {
  const _Section(
    this.id,
    this.choices, {
    required this.storeKey,
    required this.sideBySide,
    this.byDefault,
  });

  final String id;
  final List<String> choices;
  final String storeKey;
  final String? byDefault;

  /// A tall preview: the cards share one row. Otherwise they are stacked.
  final bool sideBySide;

  String get defaultChoice => byDefault ?? choices.first;
  String get other => choices.lastWhere((choice) => choice != defaultChoice);
  ValueKey<String> get defaultCard => _card(id, defaultChoice);
  ValueKey<String> get otherCard => _card(id, other);
  List<ValueKey<String>> get cards => [
    for (final choice in choices) _card(id, choice),
  ];
}

// « compact » (the Modern composer) is shown first; « classic », today's bar,
// is the default.
const _composer = _Section(
  'composer',
  ['compact', 'classic'],
  storeKey: SettingKeys.composerStyle,
  sideBySide: false,
  byDefault: 'classic',
);

// The search of the chat list on a phone (D37): the bottom bar, today's
// search and the default, is shown first; « collapsing » is the thin field
// at the top of the list. A chat list drawn tall: the cards share one row.
const _search = _Section(
  'search-bar',
  ['bottomBar', 'collapsing'],
  storeKey: SettingKeys.searchStyle,
  sideBySide: true,
);

/// Every option, in the order of the start flow.
const _allSections = [
  _Section(
    'density',
    ['comfortable', 'compact'],
    storeKey: SettingKeys.chatListDensity,
    sideBySide: true,
  ),
  _Section(
    'order',
    ['recent', 'sections'],
    storeKey: SettingKeys.roomOrder,
    sideBySide: true,
  ),
  _search,
  _Section(
    'seen-style',
    ['ticks', 'avatars', 'names'],
    storeKey: SettingKeys.seenStyle,
    sideBySide: false,
  ),
  _composer,
  _Section(
    'align',
    ['ownRight', 'left'],
    storeKey: SettingKeys.bubbleAlign,
    sideBySide: false,
  ),
];

/// The options of a wide screen: no search bar, its search stays in the
/// header (D37).
final _wideSections = [
  for (final section in _allSections)
    if (section != _search) section,
];

/// The options of a phone: no composer, the phone keeps today's input bar.
final _phoneSections = [
  for (final section in _allSections)
    if (section != _composer) section,
];

/// Settings › Personalization on a screen of [size].
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Size size = _phone,
  Map<String, Object> stored = const {},
}) async {
  SharedPreferences.setMockInitialValues(stored);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer.test(retry: (_, _) => null);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: const SettingsPersonalization(),
      ),
    ),
  );
  await _settle(tester);
  return container;
}

/// Lets the storage answer. Not `pumpAndSettle`: a preview may animate for
/// ever.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _tap(WidgetTester tester, Key card) async {
  await tester.ensureVisible(find.byKey(card));
  await tester.pump();
  await tester.tap(find.byKey(card));
  await _settle(tester);
}

bool _chosen(WidgetTester tester, Key card) =>
    isAnnouncedAsChosen(tester, find.byKey(card));

/// Any option card of the step [id], whatever its choices.
Finder _anyCardOf(String id) => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('option-$id-'),
);

/// The name of the choice the app holds for the section [id] now.
String _current(ProviderContainer container, String id) {
  final preferences = container
      .read(displayPreferencesControllerProvider)
      .requireValue;
  return switch (id) {
    'density' => preferences.density.name,
    'order' => preferences.roomOrder.name,
    'seen-style' => preferences.seenStyle.name,
    'composer' => preferences.composerStyle.name,
    'align' => preferences.bubbleAlign.name,
    'search-bar' => preferences.searchStyle.name,
    _ => throw ArgumentError(id),
  };
}

/// On each of [sections], the card [chosen] names alone is chosen.
void _expectChosen(
  WidgetTester tester,
  List<_Section> sections,
  ValueKey<String> Function(_Section section) chosen,
) {
  for (final section in sections) {
    for (final card in section.cards) {
      expect(_chosen(tester, card), card == chosen(section), reason: '$card');
    }
  }
}

/// Where the cards of [section] are, in the order shown.
List<Rect> _rectsOf(WidgetTester tester, _Section section) => [
  for (final card in section.cards) tester.getRect(find.byKey(card)),
];

/// [rect] is within the width of a phone.
void _expectOnThePhone(Rect rect) {
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(390));
}

/// Each rect of [rects] with the one shown just before it.
List<(Rect, Rect)> _neighbours(List<Rect> rects) => [
  for (var i = 1; i < rects.length; i++) (rects[i - 1], rects[i]),
];

/// The cards of [section] share one row, left to right, on the phone.
void _expectOneRow(WidgetTester tester, _Section section) {
  final rects = _rectsOf(tester, section);
  for (final (index, rect) in rects.indexed) {
    expect(rect.top, rects.first.top, reason: '${section.cards[index]}');
    _expectOnThePhone(rect);
  }
  for (final (before, after) in _neighbours(rects)) {
    expect(before.right, lessThanOrEqualTo(after.left));
  }
}

/// The cards of [section] are stacked, one wide card per row, top to bottom.
void _expectStacked(WidgetTester tester, _Section section) {
  final rects = _rectsOf(tester, section);
  for (final (index, rect) in rects.indexed) {
    expect(rect.left, rects.first.left, reason: '${section.cards[index]}');
    _expectOnThePhone(rect);
    expect(rect.width, greaterThan(rect.height));
  }
  for (final (before, after) in _neighbours(rects)) {
    expect(before.bottom, lessThanOrEqualTo(after.top));
  }
}

final _en = lookupL10n(const Locale('en'));

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  for (final (name, size, sections) in [
    ('a phone 390 px wide', _phone, _phoneSections),
    ('a screen 1200 px wide', _wide, _wideSections),
  ]) {
    _screenTests(name, size, sections);
    _screenChoiceTests(name, size, sections);
  }
  _composerTests();
  _searchBarTests();
  _choicesTests();
  _phoneLayoutTests();
  _orderPreviewTests();
  _everyStepLayoutTests();
}

void _screenTests(String name, Size size, List<_Section> sections) {
  group('Settings › Personalization on $name', () {
    testWidgets('is titled « Personalization »', (tester) async {
      await _pump(tester, size: size);

      expect(find.text('Personalization'), findsOneWidget);
    });

    testWidgets('shows the cards of the ${sections.length} options on one '
        'screen', (tester) async {
      await _pump(tester, size: size);

      for (final section in sections) {
        for (final card in section.cards) {
          expect(find.byKey(card), findsOneWidget, reason: '$card');
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers no theme: the app stays light', (tester) async {
      await _pump(tester, size: size);

      expect(_anyCardOf('theme'), findsNothing);
    });

    testWidgets('the options come in the order of the start flow', (
      tester,
    ) async {
      await _pump(tester, size: size);

      final tops = [
        for (final section in sections)
          tester.getRect(find.byKey(section.cards.first)).top,
      ];
      expect(tops, [...tops]..sort());
      expect(tops.toSet().length, tops.length);
    });

    testWidgets('fits without an overflow, with larger text too', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pump(tester, size: size);

      expect(tester.takeException(), isNull);
    });
  });
}

void _screenChoiceTests(String name, Size size, List<_Section> sections) {
  group('Settings › Personalization on $name, what is chosen', () {
    testWidgets('a device never asked shows the default of each option as '
        'chosen', (tester) async {
      await _pump(tester, size: size);

      _expectChosen(tester, sections, (section) => section.defaultCard);
    });

    testWidgets('shows what the device stored as chosen', (tester) async {
      await _pump(
        tester,
        size: size,
        stored: {
          for (final section in sections) section.storeKey: section.other,
        },
      );

      _expectChosen(tester, sections, (section) => section.otherCard);
    });

    for (final section in sections) {
      testWidgets('a tap on « ${section.other} » of ${section.id} applies '
          'it at once and keeps it on the device', (tester) async {
        final container = await _pump(tester, size: size);

        await _tap(tester, _card(section.id, section.other));

        expect(_current(container, section.id), section.other);
        expect(_chosen(tester, _card(section.id, section.other)), isTrue);
        expect(_chosen(tester, section.defaultCard), isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(section.storeKey), section.other);
      });
    }
  });
}

void _composerTests() {
  group('Settings › Personalization, the composer', () {
    testWidgets('a phone has no composer option', (tester) async {
      await _pump(tester);

      expect(_anyCardOf('composer'), findsNothing);
    });

    testWidgets('a wide screen places the composer between the seen style '
        'and the align', (tester) async {
      await _pump(tester, size: _wide);

      final seenStyle = tester.getRect(
        find.byKey(_card('seen-style', 'ticks')),
      );
      final composer = tester.getRect(find.byKey(_card('composer', 'compact')));
      final align = tester.getRect(find.byKey(_card('align', 'ownRight')));
      expect(seenStyle.top, lessThan(composer.top));
      expect(composer.top, lessThan(align.top));
    });

    testWidgets('a wide screen shows « compact » first, « classic » chosen on '
        'arrival', (tester) async {
      await _pump(tester, size: _wide);

      final compact = tester.getRect(find.byKey(_card('composer', 'compact')));
      final classic = tester.getRect(find.byKey(_card('composer', 'classic')));
      expect(
        compact.top < classic.top ||
            (compact.top == classic.top && compact.left < classic.left),
        isTrue,
        reason: 'compact $compact, classic $classic',
      );
      expect(_chosen(tester, _card('composer', 'classic')), isTrue);
      expect(_chosen(tester, _card('composer', 'compact')), isFalse);
    });
  });
}

void _searchBarTests() {
  group('Settings › Personalization, the search of the chat list', () {
    testWidgets('a wide screen has no search bar option', (tester) async {
      await _pump(tester, size: _wide);

      expect(_anyCardOf('search-bar'), findsNothing);
    });

    testWidgets('a wide screen that stored « collapsing » still has no search '
        'bar option', (tester) async {
      await _pump(
        tester,
        size: _wide,
        stored: {SettingKeys.searchStyle: 'collapsing'},
      );

      expect(_anyCardOf('search-bar'), findsNothing);
    });

    testWidgets('a phone places the search bar between the order and the '
        'seen style', (tester) async {
      await _pump(tester);

      final order = tester.getRect(find.byKey(_card('order', 'recent')));
      final search = tester.getRect(
        find.byKey(_card('search-bar', 'bottomBar')),
      );
      final seenStyle = tester.getRect(
        find.byKey(_card('seen-style', 'ticks')),
      );
      expect(order.top, lessThan(search.top));
      expect(search.top, lessThan(seenStyle.top));
    });

    testWidgets('a phone shows « bottomBar » first, chosen on arrival', (
      tester,
    ) async {
      await _pump(tester);

      final bottomBar = tester.getRect(
        find.byKey(_card('search-bar', 'bottomBar')),
      );
      final collapsing = tester.getRect(
        find.byKey(_card('search-bar', 'collapsing')),
      );
      expect(bottomBar.left, lessThan(collapsing.left));
      expect(_chosen(tester, _card('search-bar', 'bottomBar')), isTrue);
      expect(_chosen(tester, _card('search-bar', 'collapsing')), isFalse);
    });

    testWidgets('« collapsing » chosen, then « bottomBar » again: back to the '
        'bottom bar, kept on the device', (tester) async {
      final container = await _pump(
        tester,
        stored: {SettingKeys.searchStyle: 'collapsing'},
      );

      await _tap(tester, _card('search-bar', 'bottomBar'));

      expect(_current(container, 'search-bar'), 'bottomBar');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SettingKeys.searchStyle), 'bottomBar');
    });
  });
}

void _choicesTests() {
  group('Settings › Personalization, choices', () {
    testWidgets('a choice can be taken back', (tester) async {
      final container = await _pump(
        tester,
        stored: {SettingKeys.chatListDensity: 'compact'},
      );

      await _tap(tester, _card('density', 'comfortable'));

      expect(_current(container, 'density'), 'comfortable');
      expect(_chosen(tester, _card('density', 'comfortable')), isTrue);
      expect(_chosen(tester, _card('density', 'compact')), isFalse);
    });

    testWidgets('choosing one option leaves the others as they were', (
      tester,
    ) async {
      const others = {
        'align': 'left',
        'seen-style': 'names',
        'composer': 'compact',
      };
      final container = await _pump(
        tester,
        size: _wide,
        stored: {
          SettingKeys.bubbleAlign: 'left',
          SettingKeys.seenStyle: 'names',
          SettingKeys.composerStyle: 'compact',
        },
      );

      await _tap(tester, _card('density', 'compact'));

      for (final MapEntry(key: id, value: choice) in others.entries) {
        expect(_current(container, id), choice, reason: id);
        expect(_chosen(tester, _card(id, choice)), isTrue, reason: id);
      }
    });

    testWidgets('follows a choice made elsewhere, as in the start flow', (
      tester,
    ) async {
      final container = await _pump(tester);

      container
          .read(displayPreferencesControllerProvider.notifier)
          .setSeenStyle(SeenStyle.avatars);
      await _settle(tester);

      expect(_chosen(tester, _card('seen-style', 'avatars')), isTrue);
      expect(_chosen(tester, _card('seen-style', 'ticks')), isFalse);
    });
  });
}

void _phoneLayoutTests() {
  group('Settings › Personalization layout on a phone 390 px wide', () {
    for (final (sideBySide, layout, expectLayout) in [
      (true, 'share one row,', _expectOneRow),
      (false, 'are stacked, one per row,', _expectStacked),
    ]) {
      for (final section in _phoneSections.where(
        (s) => s.sideBySide == sideBySide,
      )) {
        testWidgets('the ${section.id} cards $layout in order', (tester) async {
          await _pump(tester);

          expectLayout(tester, section);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

void _orderPreviewTests() {
  group('Settings › Personalization, the drawing of « sections »', () {
    testWidgets('shows unread, then groups, then direct chats, as the chat '
        'list orders them', (tester) async {
      await _pump(tester);

      final card = find.byKey(_card('order', 'sections'));
      final tops = [
        for (final title in [_en.unread, _en.groups, _en.directChats])
          tester
              .getRect(find.descendant(of: card, matching: find.text(title)))
              .top,
      ];
      expect(tops, [...tops]..sort(), reason: 'unread, groups, directs');
      expect(tops.toSet().length, tops.length);
    });
  });
}

// Each step picks how its cards are laid out (`sideBySide` above): a new step
// fails here until it is listed with its layout, instead of falling into one
// unseen (review of #3841).
void _everyStepLayoutTests() {
  group('Settings › Personalization, the layout of each step', () {
    for (final step in PersonalizeStep.values) {
      test('${step.id} has its layout chosen', () {
        expect(
          _allSections.map((section) => section.id),
          contains(step.id),
          reason: 'list ${step.id} in _allSections, with its sideBySide',
        );
      });
    }

    // Wide only, so the phone layout cases above never see it.
    testWidgets('on a wide screen, the composer cards are stacked, one per '
        'row, in order', (tester) async {
      await _pump(tester, size: _wide);

      // _expectStacked holds the cards to the width of a phone: not here.
      final rects = _rectsOf(tester, _composer);
      for (final rect in rects) {
        expect(rect.left, rects.first.left);
      }
      for (final (before, after) in _neighbours(rects)) {
        expect(before.bottom, lessThanOrEqualTo(after.top));
      }
      expect(tester.takeException(), isNull);
    });
  });
}
