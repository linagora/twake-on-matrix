import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/floating_navigation_bar.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../../../fake_client.dart';
import '../../../pages/activity/activity_test_support.dart';
import '../../../pages/chat_list/chat_list_header_test_harness.dart'
    show FakeMatrixState;
import '../../../providers/fake_active_account.dart';

// `NavigationKeys.searchButton`, `.searchField` (on the TextField) and
// `.searchCloseButton`.
const _searchButton = Key('navigation.searchButton');
const _searchField = Key('navigation.searchField');
const _closeButton = Key('navigation.searchCloseButton');

const _screen = Size(400, 800);

const _tabs = [
  AdaptiveDestinationEnum.contacts,
  AdaptiveDestinationEnum.rooms,
  AdaptiveDestinationEnum.activity,
];

/// The search of the Chats tab, as the screen that shows the bar holds it.
class _Search {
  final open = ValueNotifier(false);
  final query = TextEditingController();

  void dispose() {
    open.dispose();
    query.dispose();
  }
}

/// The bar of the Chats tab, with its search; [withSearch] false: the bar of
/// Contacts and Activity, which have none.
Future<_Search> _pumpBar(
  WidgetTester tester, {
  bool withSearch = true,
  TextDirection direction = TextDirection.ltr,
  bool appTheme = false,
}) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final client = Client('testclient', database: EventIdListDatabase(const []));
  final repository = FakeActivityRepository();
  addTearDown(repository.close);
  final search = _Search();
  addTearDown(search.dispose);
  await tester.pumpWidget(
    provider.Provider<MatrixState>.value(
      value: FakeMatrixState(client),
      child: UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            ...activeAccountOverrides(client),
            activityRepositoryProvider.overrideWithValue(repository),
          ],
        ),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          builder: (context, child) => Directionality(
            textDirection: direction,
            // The theme of the app styles its text fields.
            child: appTheme
                ? Theme(
                    data: TwakeThemes.buildTheme(context, Brightness.light),
                    child: child!,
                  )
                : child!,
          ),
          home: Scaffold(
            body: const Center(child: Text('the screen')),
            bottomNavigationBar: FloatingNavigationBar(
              destinations: AdaptiveDestinationEnum.values,
              selected: AdaptiveDestinationEnum.rooms,
              onDestinationSelected: (_) {},
              searchOpen: withSearch ? search.open : null,
              searchQuery: withSearch ? search.query : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return search;
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.byKey(_searchButton));
  await tester.pumpAndSettle();
}

Finder _tab(AdaptiveDestinationEnum destination) =>
    find.byKey(destination.navigationKey).hitTestable();

void _expectTabs(Matcher matcher) {
  for (final tab in _tabs) {
    expect(_tab(tab), matcher, reason: '$tab');
  }
}

bool _fieldFocused(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(_searchField),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode
    .hasFocus;

void main() {
  setUpAll(() {
    // Read by the theme of the app.
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  _closedTests();
  _openTests();
  _closeTests();
  _alignmentTests();
}

void _closedTests() {
  group('FloatingNavigationBar search, closed', () {
    testWidgets('GIVEN the Chats tab\n'
        'THEN a round search button sits at the end of the bar, the tabs '
        'beside it', (tester) async {
      await _pumpBar(tester);

      _expectTabs(findsOneWidget);
      final button = tester.getRect(find.byKey(_searchButton).hitTestable());
      final lastTab = tester.getRect(_tab(AdaptiveDestinationEnum.activity));
      expect(button.left, greaterThanOrEqualTo(lastTab.right));
      expect(button.right, lessThanOrEqualTo(_screen.width));
      expect(button.width, moreOrLessEquals(button.height));
      expect(find.byKey(_searchField), findsNothing);
      expect(find.byKey(_closeButton), findsNothing);
    });

    testWidgets('GIVEN the Chats tab\n'
        'THEN a screen reader hears the button as « Search »', (tester) async {
      await _pumpBar(tester);

      expect(find.bySemanticsLabel('Search'), findsOneWidget);
    });

    testWidgets('GIVEN a right-to-left language\n'
        'THEN the search button is on the left, the end of the bar', (
      tester,
    ) async {
      await _pumpBar(tester, direction: TextDirection.rtl);

      final button = tester.getRect(find.byKey(_searchButton));
      for (final tab in _tabs) {
        expect(button.right, lessThanOrEqualTo(tester.getRect(_tab(tab)).left));
      }
    });

    testWidgets('GIVEN a tab without search (Contacts, Activity)\n'
        'THEN the bar has no search button', (tester) async {
      await _pumpBar(tester, withSearch: false);

      _expectTabs(findsOneWidget);
      expect(find.byKey(_searchButton), findsNothing);
    });
  });
}

void _openTests() {
  group('FloatingNavigationBar search, open', () {
    testWidgets('WHEN the search button is tapped\n'
        'THEN a focused search field takes the place of the tabs', (
      tester,
    ) async {
      final search = await _pumpBar(tester);

      await _openSearch(tester);

      expect(search.open.value, isTrue);
      expect(find.byKey(_searchField).hitTestable(), findsOneWidget);
      expect(_fieldFocused(tester), isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      _expectTabs(findsNothing);
    });

    testWidgets('WHEN the search is open\n'
        'THEN the field fills the bar from its start, a round close button '
        'at its end', (tester) async {
      await _pumpBar(tester);
      final tabsLeft = tester.getRect(_tab(AdaptiveDestinationEnum.contacts));

      await _openSearch(tester);

      final field = tester.getRect(find.byKey(_searchField));
      final close = tester.getRect(find.byKey(_closeButton).hitTestable());
      expect(field.left, lessThanOrEqualTo(tabsLeft.right));
      expect(close.left, greaterThanOrEqualTo(field.right));
      expect(close.right, lessThanOrEqualTo(_screen.width));
      expect(close.width, moreOrLessEquals(close.height));
    });

    testWidgets('WHEN the search is open\n'
        'THEN a screen reader hears the close button as « Close »', (
      tester,
    ) async {
      await _pumpBar(tester);

      await _openSearch(tester);

      expect(find.bySemanticsLabel('Close'), findsOneWidget);
    });

    testWidgets('WHEN the user types in the field\n'
        'THEN the query follows', (tester) async {
      final search = await _pumpBar(tester);
      await _openSearch(tester);

      await tester.enterText(find.byKey(_searchField), 'taisiya');
      await tester.pump();

      expect(search.query.text, 'taisiya');
    });

    testWidgets('WHEN the screen opens the search itself\n'
        'THEN the bar shows the field', (tester) async {
      final search = await _pumpBar(tester);

      search.open.value = true;
      await tester.pumpAndSettle();

      expect(find.byKey(_searchField).hitTestable(), findsOneWidget);
      _expectTabs(findsNothing);
    });
  });
}

void _closeTests() {
  group('FloatingNavigationBar search, closing', () {
    testWidgets('WHEN the close button is tapped\n'
        'THEN the tabs come back and the query is emptied', (tester) async {
      final search = await _pumpBar(tester);
      await _openSearch(tester);
      await tester.enterText(find.byKey(_searchField), 'taisiya');

      await tester.tap(find.byKey(_closeButton));
      await tester.pumpAndSettle();

      expect(search.open.value, isFalse);
      expect(search.query.text, isEmpty);
      _expectTabs(findsOneWidget);
      expect(find.byKey(_searchButton).hitTestable(), findsOneWidget);
      expect(find.byKey(_searchField), findsNothing);
      expect(find.byKey(_closeButton), findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('WHEN Android back is pressed while the search is open\n'
        'THEN the search closes, the query is emptied, the screen stays', (
      tester,
    ) async {
      final search = await _pumpBar(tester);
      await _openSearch(tester);
      await tester.enterText(find.byKey(_searchField), 'taisiya');

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(search.open.value, isFalse);
      expect(search.query.text, isEmpty);
      _expectTabs(findsOneWidget);
      expect(find.text('the screen'), findsOneWidget);
    });

    testWidgets('WHEN the search is opened again after a close\n'
        'THEN the field is empty', (tester) async {
      await _pumpBar(tester);
      await _openSearch(tester);
      await tester.enterText(find.byKey(_searchField), 'taisiya');
      await tester.tap(find.byKey(_closeButton));
      await tester.pumpAndSettle();

      await _openSearch(tester);

      expect(find.text('taisiya'), findsNothing);
      expect(_fieldFocused(tester), isTrue);
    });
  });
}

// Review of 2026-11-27 (screenshot): in the open field the placeholder, the
// caret and the typed text sit higher than the search icon.
void _alignmentTests() {
  group('FloatingNavigationBar search, open: vertical alignment', () {
    for (final (name, text) in [
      ('the placeholder', null),
      ('the caret', null),
      ('the typed text', 'taisiya'),
    ]) {
      testWidgets(
        'THEN $name is vertically centred with the search icon',
        (tester) async {
          await _pumpBar(tester, appTheme: true);
          await _openSearch(tester);
          if (text != null) {
            await tester.enterText(find.byKey(_searchField), text);
            await tester.pumpAndSettle();
          }

          Finder inField(Finder matching) =>
              find.descendant(of: find.byKey(_searchField), matching: matching);
          final icon = tester.getCenter(inField(find.byIcon(Icons.search))).dy;
          final line = inField(
            name == 'the placeholder'
                ? find.text('Search')
                : find.byType(EditableText),
          );
          expect(tester.getCenter(line).dy, moreOrLessEquals(icon, epsilon: 1));
        },
        variant: const TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.iOS,
        }),
      );
    }
  });
}
