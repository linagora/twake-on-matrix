import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/widget_keys/navigation_keys.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';

import '../../../pages/activity/activity_test_support.dart';
import '../../../providers/fake_active_account.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 1: the bar
/// goes Contacts · Chats · Activity · Settings, on the phone bar and on the
/// side bar of a wide screen. The Activity tab carries a badge: the unread
/// mentions count, nothing at zero (web D182, D568).
void main() {
  late FakeActivityRepository repository;

  Finder activityTab() => find.byKey(NavigationKeys.activityDestination.key);

  Future<void> pumpBar(WidgetTester tester, {required bool wide}) async {
    final profile = ValueNotifier<Profile?>(null);
    addTearDown(profile.dispose);
    addTearDown(repository.close);
    // Contacts and Activity: Chats and Settings read the Matrix widget.
    const shown = [
      AdaptiveDestinationEnum.contacts,
      AdaptiveDestinationEnum.activity,
    ];
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          ...activeAccountOverrides(accountClient('@me:example.org')),
          activityRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              bottomNavigationBar: wide
                  ? NavigationBar(
                      destinations: [
                        for (final destination in shown)
                          destination.getNavigationDestination(
                            context,
                            profile,
                          ),
                      ],
                    )
                  : BottomNavigationBar(
                      items: [
                        for (final destination in shown)
                          destination.getNavigationDestinationForBottomBar(
                            context,
                            profile,
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('the destinations are Contacts, Chats, Activity, Settings', () {
    expect(AdaptiveDestinationEnum.values.map((d) => d.name), [
      'contacts',
      'rooms',
      'activity',
      'settings',
    ]);
  });

  for (final wide in [false, true]) {
    final bar = wide ? 'the side bar' : 'the phone bar';

    group('on $bar', () {
      testWidgets('the Activity tab is labelled « Activity »', (tester) async {
        repository = FakeActivityRepository();
        await pumpBar(tester, wide: wide);

        expect(find.text('Activity'), findsOneWidget);
        expect(activityTab(), findsOneWidget);
      });

      testWidgets('the Activity tab shows the unread mentions count', (
        tester,
      ) async {
        repository = FakeActivityRepository(mentionCount: 4);
        await pumpBar(tester, wide: wide);

        expect(
          find.descendant(of: activityTab(), matching: find.text('4')),
          findsOneWidget,
        );
      });

      testWidgets('with no unread mention, the Activity tab shows no badge', (
        tester,
      ) async {
        repository = FakeActivityRepository();
        await pumpBar(tester, wide: wide);

        expect(activityTab(), findsOneWidget);
        expect(
          find.descendant(of: activityTab(), matching: find.text('0')),
          findsNothing,
        );
      });

      testWidgets('the badge follows the sync without a refresh', (
        tester,
      ) async {
        repository = FakeActivityRepository(mentionCount: 4);
        await pumpBar(tester, wide: wide);

        repository.setMentionCount(1);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: activityTab(), matching: find.text('1')),
          findsOneWidget,
        );

        repository.setMentionCount(0);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: activityTab(), matching: find.text('1')),
          findsNothing,
        );
        expect(
          find.descendant(of: activityTab(), matching: find.text('0')),
          findsNothing,
        );
      });
    });
  }
}
