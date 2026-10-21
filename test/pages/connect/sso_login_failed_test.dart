import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/bootstrap/init_client_dialog.dart';
import 'package:twake_chat/pages/connect/sso_login_state.dart';
import 'package:twake_chat/presentation/mixins/connect_page_mixin.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/layouts/agruments/logged_in_body_args.dart';
import 'package:twake_chat/widgets/layouts/agruments/logged_in_other_account_body_args.dart';
import 'package:twake_chat/widgets/matrix.dart';
import '../../providers/fake_login_sessions.dart';
import 'package:twake_chat/widgets/twake_app.dart';

class _FakeLoginClient extends Fake implements Client {
  int logins = 0;

  /// `login` has many optional parameters that do not matter here.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName != #login) return super.noSuchMethod(invocation);
    logins++;
    return Future.value(
      LoginResponse(
        accessToken: 'token',
        deviceId: 'device',
        userId: '@a:example.com',
      ),
    );
  }
}

class _FakeMatrixState extends Fake implements MatrixState {
  @override
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController<ClientLoginStateEvent>.broadcast();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

class _Host with ConnectPageMixin {}

void main() {
  late _FakeLoginClient client;
  late _FakeMatrixState matrix;
  late FakeLoginSessions sessions;
  late _Host host;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    client = _FakeLoginClient();
    matrix = _FakeMatrixState();
    sessions = FakeLoginSessions();
    host = _Host();
    TwakeApp.routerKey = GlobalKey<NavigatorState>();
  });

  tearDown(() async {
    await matrix.onClientLoginStateChanged.close();
    await GetIt.I.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: TwakeApp.routerKey,
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder: (context, child) =>
            Provider<MatrixState>.value(value: matrix, child: child),
        home: const Scaffold(body: SizedBox()),
      ),
    );
  }

  ClientLoginStateEvent loginFailed({
    MultipleAccountLoginType type = MultipleAccountLoginType.loginFailed,
  }) => ClientLoginStateEvent(
    client: client,
    loginState: LoginState.loggedOut,
    multipleAccountLoginType: type,
    error: StateError('the store is full'),
  );

  testWidgets(
    'a failed login closes the dialog, tells the user, ends in an error',
    (tester) async {
      await pumpApp(tester);

      final result = host.loginWithToken(sessions, client, 'token');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(InitClientDialog), findsOneWidget);
      expect(client.logins, 1);

      matrix.onClientLoginStateChanged.add(loginFailed());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));

      expect(await result, SsoLoginState.error);
      expect(find.byType(InitClientDialog), findsNothing);
      final l10n = L10n.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
      expect(find.text('the store is full'), findsNothing);
    },
  );

  testWidgets('the user can start the login again', (tester) async {
    await pumpApp(tester);
    final first = host.loginWithToken(sessions, client, 'token');
    await tester.pump(const Duration(milliseconds: 100));
    matrix.onClientLoginStateChanged.add(loginFailed());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(InitClientDialog), findsNothing);
    expect(await first, SsoLoginState.error);

    final second = host.loginWithToken(sessions, client, 'token');
    await tester.pump(const Duration(milliseconds: 100));

    expect(client.logins, 2);
    expect(find.byType(InitClientDialog), findsOneWidget);

    matrix.onClientLoginStateChanged.add(loginFailed());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(InitClientDialog), findsNothing);
    expect(await second, SsoLoginState.error);
  });

  testWidgets('closing the dialog without a failure is not an error', (
    tester,
  ) async {
    await pumpApp(tester);
    final result = host.loginWithToken(sessions, client, 'token');
    await tester.pump(const Duration(milliseconds: 100));

    Navigator.of(TwakeApp.routerKey.currentContext!).pop();
    // The dialog waits up to 30 seconds for a login state, as it always did.
    await tester.pump(const Duration(seconds: 31));

    expect(await result, SsoLoginState.success);
  });

  testWidgets(
    'a cleanup that failed also closes the dialog and ends in an error',
    (tester) async {
      await pumpApp(tester);

      final result = host.loginWithToken(sessions, client, 'token');
      await tester.pump(const Duration(milliseconds: 100));
      matrix.onClientLoginStateChanged.add(
        loginFailed(type: MultipleAccountLoginType.cleanupFailed),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(InitClientDialog), findsNothing);
      expect(await result, SsoLoginState.error);
      final l10n = L10n.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
    },
  );

  group('a login that works', () {
    Future<List<(String, Object?)>> openDialog(WidgetTester tester) async {
      final went = <(String, Object?)>[];
      await pumpApp(tester);
      unawaited(
        showDialog<Object?>(
          context: TwakeApp.routerKey.currentContext!,
          useRootNavigator: false,
          builder: (context) => InitClientDialog(
            future: () async => client.login(LoginType.mLoginToken),
            navigate: (location, {extra}) => went.add((location, extra)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(InitClientDialog), findsOneWidget);
      return went;
    }

    ClientLoginStateEvent loggedIn(MultipleAccountLoginType type) =>
        ClientLoginStateEvent(
          client: client,
          loginState: LoginState.loggedIn,
          multipleAccountLoginType: type,
        );

    testWidgets('the first account closes the dialog and opens the rooms', (
      tester,
    ) async {
      final went = await openDialog(tester);

      matrix.onClientLoginStateChanged.add(
        loggedIn(MultipleAccountLoginType.firstLoggedIn),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(InitClientDialog), findsNothing);
      expect(went, hasLength(1));
      expect(went.single.$1, '/rooms');
      expect(
        (went.single.$2 as LoggedInBodyArgs).newActiveClient,
        same(client),
      );
    });

    testWidgets('another account closes the dialog and opens the rooms', (
      tester,
    ) async {
      final went = await openDialog(tester);

      matrix.onClientLoginStateChanged.add(
        loggedIn(MultipleAccountLoginType.otherAccountLoggedIn),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(InitClientDialog), findsNothing);
      expect(went.single.$1, '/rooms');
      expect(went.single.$2, isA<LoggedInOtherAccountBodyArgs>());
    });
  });
}
