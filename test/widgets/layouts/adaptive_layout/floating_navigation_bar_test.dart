import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/floating_navigation_bar.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../../../fake_client.dart';
import '../../../pages/activity/activity_test_support.dart';
import '../../../pages/chat_list/chat_list_header_test_harness.dart'
    show FakeMatrixState;
import '../../../providers/fake_active_account.dart';

const _labels = ['Contacts', 'Chats', 'Activity', 'Settings'];

/// What the bar is pumped with.
class _Bar {
  const _Bar({
    this.selected = AdaptiveDestinationEnum.rooms,
    this.width = 400,
    this.textScale = 1,
    this.mentionCount = 0,
    this.invites = 0,
  });

  final AdaptiveDestinationEnum selected;
  final double width;
  final double textScale;
  final int mentionCount;
  final int invites;
}

Future<List<int>> _pumpBar(
  WidgetTester tester, [
  _Bar bar = const _Bar(),
]) async {
  tester.view.physicalSize = Size(bar.width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final client = Client('testclient', database: EventIdListDatabase(const []));
  for (var i = 0; i < bar.invites; i++) {
    client.rooms.add(
      Room(
        id: '!invite$i:server',
        client: client,
        membership: Membership.invite,
      ),
    );
  }
  final repository = FakeActivityRepository(mentionCount: bar.mentionCount);
  addTearDown(repository.close);
  final tapped = <int>[];
  await tester.pumpWidget(
    provider.Provider<MatrixState>.value(
      value: FakeMatrixState(client),
      child: UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            ...activeAccountOverrides(accountClient('@me:example.org')),
            activityRepositoryProvider.overrideWithValue(repository),
          ],
        ),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(bar.textScale)),
            child: child!,
          ),
          home: Scaffold(
            bottomNavigationBar: FloatingNavigationBar(
              destinations: AdaptiveDestinationEnum.values,
              selected: bar.selected,
              onDestinationSelected: tapped.add,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tapped;
}

Finder _item(AdaptiveDestinationEnum destination) =>
    find.byKey(destination.navigationKey);

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  _layoutTests();
  _selectionTests();
  _badgeTests();
  _textSizeTests();
  _keyboardTests();
}

void _layoutTests() {
  group('FloatingNavigationBar layout', () {
    testWidgets('shows Contacts, Chats, Activity, Settings in that order', (
      tester,
    ) async {
      await _pumpBar(tester);

      final xs = [
        for (final label in _labels) tester.getCenter(find.text(label)).dx,
      ];
      expect(xs, [...xs]..sort());
    });

    testWidgets('every destination has the same width', (tester) async {
      await _pumpBar(tester);

      final widths = {
        for (final destination in AdaptiveDestinationEnum.values)
          tester.getSize(_item(destination)).width,
      };
      expect(widths, hasLength(1));
    });

    testWidgets('the bar hugs its items, centred on the screen', (
      tester,
    ) async {
      await _pumpBar(tester);

      final first = tester.getRect(_item(AdaptiveDestinationEnum.contacts));
      final last = tester.getRect(_item(AdaptiveDestinationEnum.settings));
      expect((first.left + last.right) / 2, moreOrLessEquals(200));
      expect(first.left, greaterThan(16));
    });
  });
}

void _selectionTests() {
  group('FloatingNavigationBar selection', () {
    testWidgets('the selected destination is in primary, the others in '
        'onSurface', (tester) async {
      await _pumpBar(
        tester,
        const _Bar(selected: AdaptiveDestinationEnum.activity),
      );
      final colors = LinagoraSysColors.material();

      expect(_labelColor(tester, 'Activity'), colors.primary);
      for (final label in ['Contacts', 'Chats', 'Settings']) {
        expect(_labelColor(tester, label), colors.onSurface);
      }
    });

    testWidgets('the selection pill sits under the selected destination', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        const _Bar(selected: AdaptiveDestinationEnum.settings),
      );

      final pill = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is ShapeDecoration &&
            (widget.decoration as ShapeDecoration).color ==
                LinagoraSysColors.material().surface,
      );
      expect(pill, findsOneWidget);
      expect(
        tester.getRect(pill).center.dx,
        moreOrLessEquals(
          tester.getCenter(_item(AdaptiveDestinationEnum.settings)).dx,
        ),
      );
    });

    testWidgets('a tap reports the index of the destination', (tester) async {
      final tapped = await _pumpBar(tester);

      await tester.tap(_item(AdaptiveDestinationEnum.contacts));
      await tester.tap(_item(AdaptiveDestinationEnum.activity));

      expect(tapped, [0, 2]);
    });
  });
}

void _badgeTests() {
  group('FloatingNavigationBar badges', () {
    testWidgets('Chats and Activity carry their unread badges', (tester) async {
      await _pumpBar(tester, const _Bar(mentionCount: 4, invites: 2));

      expect(
        find.descendant(
          of: _item(AdaptiveDestinationEnum.activity),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _item(AdaptiveDestinationEnum.rooms),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('with nothing unread, no badge is shown', (tester) async {
      await _pumpBar(tester);

      expect(
        tester
            .widgetList<Badge>(find.byType(Badge))
            .where((badge) => badge.isLabelVisible),
        isEmpty,
      );
    });
  });
}

void _textSizeTests() {
  group('FloatingNavigationBar text size', () {
    testWidgets('the system text size does not grow the labels', (
      tester,
    ) async {
      await _pumpBar(tester, const _Bar(textScale: 3));

      // labelMedium is 12/16: a scaled label would be 48 high.
      expect(tester.getSize(find.text('Settings')).height, 16);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'on a narrow screen the labels shrink to fit, never truncated',
      (tester) async {
        await _pumpBar(tester, const _Bar(width: 240));

        expect(tester.takeException(), isNull);
        for (final destination in AdaptiveDestinationEnum.values) {
          final item = tester.getRect(_item(destination));
          final label = find.descendant(
            of: _item(destination),
            matching: find.byType(Text),
          );
          final text = tester.getRect(label.last);
          expect(text.left, greaterThanOrEqualTo(item.left));
          expect(text.right, lessThanOrEqualTo(item.right));
        }
        expect(
          tester.widget<Text>(find.text('Settings')).overflow,
          isNot(TextOverflow.ellipsis),
        );
        final fitted = find.ancestor(
          of: find.text('Settings'),
          matching: find.byType(FittedBox),
        );
        expect(
          tester.getSize(fitted).width,
          lessThan(tester.getSize(find.text('Settings')).width),
        );
      },
    );
  });
}

void _keyboardTests() {
  group('FloatingNavigationBar keyboard', () {
    testWidgets('Tab then Enter selects a destination', (tester) async {
      final tapped = await _pumpBar(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(tapped, [1]);
    });

    testWidgets('Space selects the focused destination', (tester) async {
      final tapped = await _pumpBar(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(tapped, [0]);
    });
  });
}
