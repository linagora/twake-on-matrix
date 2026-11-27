import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
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
/// the default (the first one), where it is stored and how its cards are laid
/// out on a phone.
class _Section {
  const _Section(
    this.id,
    this.choices, {
    required this.storeKey,
    required this.sideBySide,
  });

  final String id;
  final List<String> choices;
  final String storeKey;

  /// A tall preview: the cards share one row. Otherwise they are stacked.
  final bool sideBySide;

  String get defaultChoice => choices.first;
  String get other => choices.lastWhere((choice) => choice != defaultChoice);
  ValueKey<String> get defaultCard => _card(id, defaultChoice);
  ValueKey<String> get otherCard => _card(id, other);
  List<ValueKey<String>> get cards => [
    for (final choice in choices) _card(id, choice),
  ];
}

/// The options of a wide screen, in the order of the start flow.
const _wideSections = [
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
];

/// The options of a phone: the same.
const _phoneSections = _wideSections;

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
  _choicesTests();
  _phoneLayoutTests();
  _orderPreviewTests();
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
      const others = {'order': 'sections'};
      final container = await _pump(
        tester,
        size: _wide,
        stored: {SettingKeys.roomOrder: 'sections'},
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
          .setRoomOrder(RoomOrder.sections);
      await _settle(tester);

      expect(_chosen(tester, _card('order', 'sections')), isTrue);
      expect(_chosen(tester, _card('order', 'recent')), isFalse);
    });
  });
}

void _phoneLayoutTests() {
  group('Settings › Personalization layout on a phone 390 px wide', () {
    for (final section in _phoneSections.where((s) => s.sideBySide)) {
      testWidgets('the ${section.id} cards share one row, in order', (
        tester,
      ) async {
        await _pump(tester);

        final rects = _rectsOf(tester, section);
        for (final (index, rect) in rects.indexed) {
          expect(rect.top, rects.first.top, reason: '${section.cards[index]}');
          _expectOnThePhone(rect);
          if (index > 0) {
            expect(rects[index - 1].right, lessThanOrEqualTo(rect.left));
          }
        }
        expect(tester.takeException(), isNull);
      });
    }

    for (final section in _phoneSections.where((s) => !s.sideBySide)) {
      testWidgets('the ${section.id} cards are stacked, one per row, in '
          'order', (tester) async {
        await _pump(tester);

        final rects = _rectsOf(tester, section);
        for (final (index, rect) in rects.indexed) {
          expect(
            rect.left,
            rects.first.left,
            reason: '${section.cards[index]}',
          );
          _expectOnThePhone(rect);
          expect(rect.width, greaterThan(rect.height));
          if (index > 0) {
            expect(rects[index - 1].bottom, lessThanOrEqualTo(rect.top));
          }
        }
        expect(tester.takeException(), isNull);
      });
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
