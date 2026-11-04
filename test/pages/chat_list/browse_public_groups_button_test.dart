import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/browse_public_groups_button.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_page.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

import '../../domain/public_rooms/fake_public_rooms_repository.dart';

void main() {
  HomeserverSummary summaryWith({required bool isPublicGroupsEnabled}) =>
      HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.example.com'),
          ),
          additionalProperties: {
            'app.twake.chat': {
              'public_groups': {'enabled': isPublicGroupsEnabled},
            },
          },
        ),
        versions: GetVersionsResponse(versions: ['r1.6.0']),
        loginFlows: [],
      );

  late GoRouter router;

  Future<void> pumpButton(
    WidgetTester tester, {
    required bool isPublicGroupsEnabled,
  }) async {
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: BrowsePublicGroupsButton()),
        ),
        GoRoute(
          path: const PublicRoomsRoute().location,
          builder: (_, _) => const PublicRoomsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          loginHomeserverSummaryProvider.overrideWithBuild(
            (_, _) => summaryWith(isPublicGroupsEnabled: isPublicGroupsEnabled),
          ),
          publicRoomsRepositoryProvider.overrideWithValue(
            FakePublicRoomsRepository(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
        ),
      ),
    );
  }

  testWidgets('build_whenPublicGroupsAreOff_showsNothing', (tester) async {
    // Act
    await pumpButton(tester, isPublicGroupsEnabled: false);

    // Assert
    expect(find.byTooltip('Browse public groups'), findsNothing);
  });

  testWidgets('tap_whenPublicGroupsAreOn_opensThePublicGroups', (tester) async {
    // Arrange
    await pumpButton(tester, isPublicGroupsEnabled: true);

    // Act
    await tester.tap(find.byTooltip('Browse public groups'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(PublicRoomsPage), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      const PublicRoomsRoute().location,
    );
  });
}
