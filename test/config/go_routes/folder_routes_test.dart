import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

/// The real `builtin` route of `$appRoutes`, under stand-ins for its parents.
GoRoute _builtinRoute(List<RouteBase> routes) {
  for (final route in routes) {
    if (route is GoRoute && route.path == 'builtin') return route;
    final found = route.routes.isEmpty ? null : _tryBuiltin(route.routes);
    if (found != null) return found;
  }
  throw StateError('No builtin route');
}

GoRoute? _tryBuiltin(List<RouteBase> routes) {
  try {
    return _builtinRoute(routes);
  } on StateError {
    return null;
  }
}

void main() {
  group('BuiltinFolderEditRoute', () {
    Future<GoRouter> open(WidgetTester tester, String location) async {
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: '/rooms',
            builder: (_, _) => const Text('rooms'),
            routes: [
              GoRoute(
                path: 'folders',
                builder: (_, _) => const Text('folders'),
                routes: [_builtinRoute($appRoutes)],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('whenDeepLinkedWithoutKind_goesToTheFolders', (tester) async {
      await open(tester, '/rooms/folders/builtin');

      expect(find.text('folders'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('whenTheKindIsUnknown_goesToTheFolders', (tester) async {
      await open(tester, '/rooms/folders/builtin?kind=future');

      expect(find.text('folders'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('location_namesItsKind', () {
      expect(
        const BuiltinFolderEditRoute(kind: BuiltinFolder.unread).location,
        '/rooms/folders/builtin?kind=unread',
      );
    });
  });
}
