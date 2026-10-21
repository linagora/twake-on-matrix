import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/login/on_auth_redirect.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

class _FakeClient extends Fake implements Client {}

class _FakeMatrixState extends Fake implements MatrixState {
  @override
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController<ClientLoginStateEvent>.broadcast();

  @override
  Future<T> trackLogin<T>(Client client, Future<T> Function() login) => login();

  @override
  Future<void> discardPendingLoginCandidate() async {}

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

void main() {
  late _FakeMatrixState matrix;
  late GoRouter router;
  final homeLocation = const HomeRoute().location;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    matrix = _FakeMatrixState();
    // The app config never arrives, so the token login stays pending and only
    // the failure event can move the page.
    AppConfig.initConfigCompleter = Completer<bool>();
    TwakeApp.routerKey = GlobalKey<NavigatorState>();
    router = GoRouter(
      navigatorKey: TwakeApp.routerKey,
      initialLocation: '/auth?loginToken=token',
      routes: [
        GoRoute(
          path: '/auth',
          builder: (context, state) => const OnAuthRedirect(),
        ),
        GoRoute(
          path: homeLocation,
          builder: (context, state) => const Scaffold(body: Text('home page')),
        ),
      ],
    );
  });

  tearDown(() async {
    await matrix.onClientLoginStateChanged.close();
    await GetIt.I.reset();
  });

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      builder: (context, child) =>
          Provider<MatrixState>.value(value: matrix, child: child),
    ),
  );

  ClientLoginStateEvent event(MultipleAccountLoginType type) =>
      ClientLoginStateEvent(
        client: _FakeClient(),
        loginState: LoginState.loggedOut,
        multipleAccountLoginType: type,
        error: StateError('the store is full'),
      );

  testWidgets('a failed login tells the user and goes back to the start', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(OnAuthRedirect), findsOneWidget);

    matrix.onClientLoginStateChanged.add(
      event(MultipleAccountLoginType.loginFailed),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('home page'), findsOneWidget);
    expect(find.byType(OnAuthRedirect), findsNothing);
    final l10n = L10n.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
    expect(find.text('the store is full'), findsNothing);
  });

  testWidgets('the user can start the login again from the start', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump(const Duration(seconds: 1));
    matrix.onClientLoginStateChanged.add(
      event(MultipleAccountLoginType.loginFailed),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    router.go('/auth?loginToken=token2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnAuthRedirect), findsOneWidget);
  });

  testWidgets(
    'a cleanup that failed also tells the user and goes back to the start',
    (tester) async {
      await pumpApp(tester);
      await tester.pump(const Duration(seconds: 1));

      matrix.onClientLoginStateChanged.add(
        event(MultipleAccountLoginType.cleanupFailed),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('home page'), findsOneWidget);
      final l10n = L10n.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
    },
  );
}
