import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/login/login.dart';
import 'package:twake_chat/pages/login/login_client_owner.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../../providers/fake_login_sessions.dart';

class _FakeClient extends Fake implements Client {
  @override
  Uri? get homeserver => Uri.parse('https://example.com');
}

class _LoggedInMatrixState extends Fake implements MatrixState {
  final _client = _FakeClient();

  @override
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController<ClientLoginStateEvent>.broadcast();

  @override
  bool isLoggedInClient() => true;

  @override
  Future<Client> getLoginClient() async => _client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_LoggedInMatrixState';
}

Iterable<RouteBase> _allRoutes(RouteBase route) => [
  route,
  ...route.routes.expand(_allRoutes),
];

GoRoute _addAccountRoute() => _allRoutes(
  $roomsShellRoute,
).whereType<GoRoute>().firstWhere((r) => r.path == 'addaccount');

void main() {
  late _LoggedInMatrixState matrix;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    matrix = _LoggedInMatrixState();
  });

  tearDown(() async {
    await matrix.onClientLoginStateChanged.close();
    await GetIt.I.reset();
  });

  testWidgets(
    'push_whenTheAddAccountLoginRouteCarriesAClientOwner_opensTheLoginPage',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/rooms',
        routes: [
          GoRoute(
            path: '/rooms',
            builder: (_, _) => const SizedBox(),
            routes: [_addAccountRoute()],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginSessionsProvider.overrideWithValue(
              FakeLoginSessions(loginClient: matrix.getLoginClient),
            ),
          ],
          child: MaterialApp.router(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            builder: (context, child) =>
                Provider<MatrixState>.value(value: matrix, child: child),
            routerConfig: router,
          ),
        ),
      );

      unawaited(
        router.push(
          const AddAccountLoginRoute().location,
          extra: LoginClientOwner.caller,
        ),
      );
      await tester.pumpAndSettle();

      final login = tester.widget<Login>(find.byType(Login));
      expect(login.owner, LoginClientOwner.caller);
    },
  );
}
