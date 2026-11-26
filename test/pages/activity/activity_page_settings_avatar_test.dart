import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:twake_chat/data/repository/activity/activity_mentions_repository.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_reactions_repository.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/activity/activity_page.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

import '../../providers/fake_active_account.dart';
import 'activity_mentions_test_support.dart';
import 'activity_reactions_test_support.dart';
import 'activity_test_support.dart';

/// `NavigationKeys.settingsAvatar`.
const _avatar = Key('navigation.settingsAvatar');

/// The Activity tab with nothing in it; returns how many times it asked for
/// Settings.
Future<List<void>> _pumpActivity(
  WidgetTester tester, {
  bool wide = false,
}) async {
  tester.view.physicalSize = wide
      ? const Size(1280, 900)
      : const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
    GetIt.instance.registerSingleton(ResponsiveUtils());
  }
  final repository = FakeActivityRepository();
  addTearDown(repository.close);
  final reactions = FakeActivityReactionsRepository();
  addTearDown(reactions.close);
  final opened = <void>[];
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        ...activeAccountOverrides(accountClient('@me:example.org')),
        activityRepositoryProvider.overrideWithValue(repository),
        activityMentionsRepositoryProvider.overrideWithValue(
          FakeActivityMentionsRepository(),
        ),
        activityReactionsRepositoryProvider.overrideWithValue(reactions),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: ActivityPage(onOpenSettings: () => opened.add(null)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  group('[Activity] settings avatar', () {
    testWidgets('GIVEN a phone\n'
        'THEN the avatar of the user sits at the start of the app bar', (
      tester,
    ) async {
      await _pumpActivity(tester);

      expect(
        find.descendant(of: find.byKey(_avatar), matching: find.byType(Avatar)),
        findsOneWidget,
      );
      final avatar = tester.getRect(find.byKey(_avatar));
      expect(
        avatar.right,
        lessThan(tester.getRect(find.text('Activity')).left),
      );
      expect(
        avatar.bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(AppBar)).bottom),
      );
    });

    testWidgets('GIVEN a phone\n'
        'WHEN the avatar is tapped\n'
        'THEN Settings opens', (tester) async {
      final opened = await _pumpActivity(tester);

      await tester.tap(find.byKey(_avatar));
      await tester.pump();

      expect(opened, hasLength(1));
    });

    testWidgets('GIVEN a wide screen\n'
        'THEN the app bar has no avatar', (tester) async {
      await _pumpActivity(tester, wide: true);

      expect(find.text('Activity'), findsOneWidget);
      expect(find.byKey(_avatar), findsNothing);
    });
  });
}
