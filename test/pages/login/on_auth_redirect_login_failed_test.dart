import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/login/on_auth_redirect.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/widgets/matrix.dart';
import '../../providers/fake_login_sessions.dart';
import 'package:twake_chat/widgets/twake_app.dart';

class _FakeClient extends Fake implements Client {
  /// The homeserver check never ends, so the login stays pending and only the
  /// failure events can move the page.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      invocation.memberName == #checkHomeserver
      ? Completer<Never>().future
      : super.noSuchMethod(invocation);
}

class _FakeMatrixState extends Fake implements MatrixState {
  final loginClient = _FakeClient();

  @override
  String? loginType;

  @override
  Future<Client> getLoginClient() async => loginClient;

  @override
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController<ClientLoginStateEvent>.broadcast();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

void main() {
  late _FakeMatrixState matrix;
  late FakeLoginSessions sessions;
  late GoRouter router;
  final homeLocation = const HomeRoute().location;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    matrix = _FakeMatrixState();
    sessions = FakeLoginSessions();
    TwakeApp.routerKey = GlobalKey<NavigatorState>();
    router = GoRouter(
      navigatorKey: TwakeApp.routerKey,
      initialLocation: '/auth?loginToken=token&homeserver=https://example.com',
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

  Future<void> pumpApp(WidgetTester tester) {
    AppConfig.initConfigCompleter = Completer<bool>()..complete(true);
    return tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder: (context, child) => ProviderScope(
          overrides: [
            loginHostSlotProvider.overrideWithValue(
              FakeLoginHostSlot(sessions),
            ),
          ],
          child: Provider<MatrixState>.value(value: matrix, child: child),
        ),
      ),
    );
  }

  ClientLoginStateEvent event(
    MultipleAccountLoginType type, {
    Client? client,
  }) => ClientLoginStateEvent(
    client: client ?? matrix.loginClient,
    loginState: LoginState.loggedOut,
    multipleAccountLoginType: type,
    error: StateError('the store is full'),
  );

  testWidgets('a failed login tells the user and goes back to the start', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
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
    await tester.pump();
    matrix.onClientLoginStateChanged.add(
      event(MultipleAccountLoginType.loginFailed),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    router.go('/auth?loginToken=token2&homeserver=https://example.com');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnAuthRedirect), findsOneWidget);
  });

  testWidgets(
    'a cleanup that failed also tells the user and goes back to the start',
    (tester) async {
      await pumpApp(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      matrix.onClientLoginStateChanged.add(
        event(MultipleAccountLoginType.cleanupFailed),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('home page'), findsOneWidget);
      final l10n = L10n.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
      expect(sessions.discards, 1);
    },
  );

  testWidgets(
    'the failure of another client is not the failure of this login',
    (tester) async {
      await pumpApp(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      matrix.onClientLoginStateChanged.add(
        event(MultipleAccountLoginType.loginFailed, client: _FakeClient()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(OnAuthRedirect), findsOneWidget);
      expect(find.text('home page'), findsNothing);
      expect(sessions.discards, 0);
    },
  );
}
