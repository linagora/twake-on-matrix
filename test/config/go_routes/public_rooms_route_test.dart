import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

void main() {
  testWidgets('redirect_whenPublicGroupsAreOff_goesBackToTheRooms', (
    tester,
  ) async {
    // Arrange
    final router = GoRouter(
      initialLocation: const RoomsRoute().location,
      routes: [
        GoRoute(
          path: const RoomsRoute().location,
          builder: (_, _) => const Text('rooms'),
          routes: [
            GoRoute(
              path: 'publicgroups',
              redirect: const PublicRoomsRoute().redirect,
              builder: (_, _) => const Text('public groups'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginHomeserverSummaryProvider.overrideWithBuild((_, _) => null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Act
    router.go(const PublicRoomsRoute().location);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('rooms'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      const RoomsRoute().location,
    );
  });
}
