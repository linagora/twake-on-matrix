import 'dart:async';
import 'dart:io' show SocketException;

import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/data/drive/datasources_impl/twake_sso_source.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/config/app_constants.dart';
import 'package:twake_chat/data/drive/sources/sso_token_vault.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/drive/sources/twake_sso_source.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/providers/sso_token_vault_provider.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
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
import '../../providers/fake_sso_refresh_token_store.dart';
import 'package:twake_chat/widgets/twake_app.dart';

class _FakeLoginClient extends Fake implements Client {
  int logins = 0;
  final loginTypes = <String>[];
  Object? loginError;

  @override
  Uri? homeserver;

  @override
  String? userID = '@a:example.com';

  /// Whether the server accepted the login: the client holds a token.
  bool logged = false;

  @override
  bool isLogged() => logged;

  /// `login` has many optional parameters that do not matter here.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName != #login) return super.noSuchMethod(invocation);
    logins++;
    loginTypes.add(invocation.positionalArguments.first as String);
    if (loginError != null) return Future<LoginResponse>.error(loginError!);
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
  List<Client?> clients = [];

  @override
  List<Client?> get currentClients => clients;

  @override
  String? loginType;

  @override
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController<ClientLoginStateEvent>.broadcast();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

class _Host with ConnectPageMixin {}

class _FakeTwakeSso implements TwakeSsoSource {
  _FakeTwakeSso(this._signIn);

  final Future<DriveIdToken> Function() _signIn;
  int signIns = 0;

  @override
  Future<DriveIdToken> signIn() {
    signIns++;
    return _signIn();
  }

  @override
  Future<DriveIdToken> refresh(String refreshToken) =>
      throw StateError('no refresh in a login');
}

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

  testWidgets('a login that throws tells the user and ends in an error', (
    tester,
  ) async {
    client.loginError = StateError('M_FORBIDDEN');
    await pumpApp(tester);

    final result = host.loginWithToken(sessions, client, 'token');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(await result, SsoLoginState.error);
    expect(find.byType(InitClientDialog), findsNothing);
    final l10n = L10n.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
  });

  testWidgets('logs in with the login type it is given', (tester) async {
    client.loginError = StateError('stop here');
    await pumpApp(tester);

    final result = host.loginWithToken(
      sessions,
      client,
      'id-token',
      type: AppConstants.jwtLoginType,
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await result;

    expect(client.loginTypes, ['org.matrix.login.jwt']);
  });

  testWidgets('logs in with the login token type by default', (tester) async {
    client.loginError = StateError('stop here');
    await pumpApp(tester);

    final result = host.loginWithToken(sessions, client, 'token');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await result;

    expect(client.loginTypes, [LoginType.mLoginToken]);
  });

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

  testWidgets('a login that never reports closes the dialog as a failure '
      'after the timeout', (tester) async {
    await pumpApp(tester);
    final result = host.loginWithToken(sessions, client, 'token');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(InitClientDialog), findsOneWidget);

    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 1));

    expect(await result, SsoLoginState.error);
    expect(find.byType(InitClientDialog), findsNothing);
  });

  group('a login the server accepted but that is slow to report', () {
    Future<List<(String, Object?)>> openDialog(WidgetTester tester) async {
      final went = <(String, Object?)>[];
      await pumpApp(tester);
      unawaited(
        showDialog<Object?>(
          context: TwakeApp.routerKey.currentContext!,
          useRootNavigator: false,
          builder: (context) => InitClientDialog(
            future: () async => client.login(LoginType.mLoginToken),
            account: client,
            navigate: (location, {extra}) => went.add((location, extra)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(InitClientDialog), findsOneWidget);
      return went;
    }

    testWidgets('of the first account goes to the rooms, not to a failure', (
      tester,
    ) async {
      client.logged = true;
      matrix.clients = [client];
      final went = await openDialog(tester);

      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(InitClientDialog), findsNothing);
      expect(went.single.$1, '/rooms');
      expect(
        (went.single.$2 as LoggedInBodyArgs).newActiveClient,
        same(client),
      );
    });

    testWidgets('of another account goes to the rooms as that account', (
      tester,
    ) async {
      final other = _FakeLoginClient()..logged = true;
      client.logged = true;
      matrix.clients = [other, client];
      final went = await openDialog(tester);

      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(InitClientDialog), findsNothing);
      expect(went.single.$1, '/rooms');
      expect(went.single.$2, isA<LoggedInOtherAccountBodyArgs>());
    });

    testWidgets('does not go to the rooms twice when the event comes late', (
      tester,
    ) async {
      client.logged = true;
      matrix.clients = [client];
      final went = await openDialog(tester);

      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));
      matrix.onClientLoginStateChanged.add(
        ClientLoginStateEvent(
          client: client,
          loginState: LoginState.loggedIn,
          multipleAccountLoginType: MultipleAccountLoginType.firstLoggedIn,
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(went, hasLength(1));
    });
  });

  group('ssoLoginActionMobile with a Twake SSO', () {
    late SsoTokenVault vault;
    late FakeSsoRefreshTokenStore store;

    HomeserverSummary summary({required bool jwtFlow, int providers = 1}) =>
        HomeserverSummary(
          discoveryInformation: DiscoveryInformation.fromJson({
            'm.homeserver': {'base_url': 'https://matrix.example/'},
            'm.authentication': {'issuer': 'https://sso.example'},
            'app.twake.chat': {'enable_twake_drive': true},
          }),
          versions: GetVersionsResponse(versions: const ['v1.11']),
          loginFlows: [
            LoginFlow.fromJson({
              'type': AuthenticationTypes.sso,
              'identity_providers': [
                for (var i = 0; i < providers; i++)
                  {'id': 'idp$i', 'name': 'IdP $i'},
              ],
            }),
            LoginFlow(type: LoginType.mLoginToken),
            if (jwtFlow) LoginFlow(type: AppConstants.jwtLoginType),
          ],
        );

    DriveIdToken tokens() => DriveIdToken(
      value: 'sso-id-token',
      expiresAt: DateTime.utc(2030),
      workplaceFqdn: 'alice.twake.example',
      refreshToken: 'sso-refresh-token',
    );

    Future<BuildContext> pumpLogin(
      WidgetTester tester, {
      required TwakeSsoSource source,
      bool jwtFlow = true,
      int providers = 1,
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      vault = SsoTokenVault();
      store = FakeSsoRefreshTokenStore();
      // The login reads the summary it checked, not the active account's.
      final checked = summary(jwtFlow: jwtFlow, providers: providers);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginSessionsProvider.overrideWithValue(
              FakeLoginSessions(loginClient: () async => client)
                ..homeserverSummary = checked,
            ),
            twakeSsoSourceProvider(
              checked.twakeDriveConfig,
            ).overrideWithValue(source),
            ssoTokenVaultProvider.overrideWithValue(vault),
            useSsoRefreshTokenStore(store),
          ],
          child: MaterialApp(
            navigatorKey: TwakeApp.routerKey,
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            builder: (context, child) =>
                Provider<MatrixState>.value(value: matrix, child: child),
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      );
      return tester.element(find.byType(Scaffold));
    }

    ClientLoginStateEvent loggedIn() => ClientLoginStateEvent(
      client: client,
      loginState: LoginState.loggedIn,
      multipleAccountLoginType: MultipleAccountLoginType.firstLoggedIn,
    );

    testWidgets('signs in once: the id token logs in to Matrix and its tokens '
        'wait for Drive', (tester) async {
      final source = _FakeTwakeSso(() async => tokens());
      final context = await pumpLogin(tester, source: source);

      final result = host.ssoLoginActionMobile(context: context, id: 'sso');
      await tester.pump(const Duration(milliseconds: 100));
      matrix.onClientLoginStateChanged.add(loggedIn());
      await tester.pump(const Duration(seconds: 1));

      expect(await result, SsoLoginState.success);
      expect(client.loginTypes, [AppConstants.jwtLoginType]);
      expect(vault.of('@a:example.com')?.value, 'sso-id-token');
      expect(vault.of('@a:example.com')?.refreshToken, 'sso-refresh-token');
    });

    testWidgets('keeps the refresh token for the next start', (tester) async {
      final source = _FakeTwakeSso(() async => tokens());
      final context = await pumpLogin(tester, source: source);

      final result = host.ssoLoginActionMobile(context: context, id: 'sso');
      await tester.pump(const Duration(milliseconds: 100));
      matrix.onClientLoginStateChanged.add(loggedIn());
      await tester.pump(const Duration(seconds: 1));

      expect(await result, SsoLoginState.success);
      expect(store.tokens, {'@a:example.com': 'sso-refresh-token'});
    });

    testWidgets('a secure store that fails does not fail the login', (
      tester,
    ) async {
      final source = _FakeTwakeSso(() async => tokens());
      final context = await pumpLogin(tester, source: source);
      store.failing = true;

      final result = host.ssoLoginActionMobile(context: context, id: 'sso');
      await tester.pump(const Duration(milliseconds: 100));
      matrix.onClientLoginStateChanged.add(loggedIn());
      await tester.pump(const Duration(seconds: 1));

      expect(await result, SsoLoginState.success);
      expect(vault.of('@a:example.com')?.value, 'sso-id-token');
    });

    testWidgets('keeps no tokens when the Matrix login fails', (tester) async {
      client.loginError = StateError('M_FORBIDDEN');
      final source = _FakeTwakeSso(() async => tokens());
      final context = await pumpLogin(tester, source: source);

      final result = host.ssoLoginActionMobile(context: context, id: 'sso');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));

      expect(await result, SsoLoginState.error);
      expect(vault.of('@a:example.com'), isNull);
      expect(store.tokens, isEmpty);
    });

    // What POST /login can answer for the JWT type: a refusal (401
    // M_FORBIDDEN), a rate limit (429 M_LIMIT_EXCEEDED), a stalled request and
    // a lost network (https://spec.matrix.org/v1.19/client-server-api/#post_matrixclientv3login).
    final matrixFailures = <String, Object>{
      'a refusal (M_FORBIDDEN)': MatrixException.fromJson({
        'errcode': 'M_FORBIDDEN',
        'error': 'Invalid token',
      }),
      'a rate limit (M_LIMIT_EXCEEDED)': MatrixException.fromJson({
        'errcode': 'M_LIMIT_EXCEEDED',
        'error': 'Too many requests',
        'retry_after_ms': 1000,
      }),
      'a timeout': TimeoutException('POST /login'),
      'a lost network': const SocketException('offline'),
    };
    matrixFailures.forEach((name, error) {
      testWidgets('keeps no tokens when the Matrix login ends in $name', (
        tester,
      ) async {
        client.loginError = error;
        final source = _FakeTwakeSso(() async => tokens());
        final context = await pumpLogin(tester, source: source);

        final result = host.ssoLoginActionMobile(context: context, id: 'sso');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 1));

        expect(await result, SsoLoginState.error);
        expect(client.loginTypes, [AppConstants.jwtLoginType]);
        expect(vault.of('@a:example.com'), isNull);
        expect(store.tokens, isEmpty);
      });
    });

    testWidgets('a cancelled sign-in is silent and logs nothing in', (
      tester,
    ) async {
      final source = _FakeTwakeSso(
        () async => throw const DriveSignInCancelled(),
      );
      final context = await pumpLogin(tester, source: source);

      final result = await host.ssoLoginActionMobile(context: context, id: 's');
      await tester.pump(const Duration(seconds: 1));

      expect(result, SsoLoginState.error);
      expect(client.logins, 0);
      final l10n = L10n.of(context)!;
      expect(find.text(l10n.oopsSomethingWentWrong), findsNothing);
    });

    for (final failure in <DriveException>[
      const DriveSignInFailed(DriveSignInFailure.tokenEndpoint),
      const DriveRateLimited(),
      const DriveTimedOut(),
      const DriveOffline(),
    ]) {
      testWidgets('a sign-in that fails with ${failure.runtimeType} tells the '
          'user and logs nothing in', (tester) async {
        final source = _FakeTwakeSso(() async => throw failure);
        final context = await pumpLogin(tester, source: source);

        final result = await host.ssoLoginActionMobile(
          context: context,
          id: 'sso',
        );
        await tester.pump(const Duration(seconds: 1));

        expect(result, SsoLoginState.error);
        expect(client.logins, 0);
        final l10n = L10n.of(context)!;
        expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
      });
    }

    testWidgets('keeps the provider the user chose when the homeserver offers '
        'several', (tester) async {
      final source = _FakeTwakeSso(() async => tokens());
      final context = await pumpLogin(tester, source: source, providers: 2);
      client.homeserver = Uri.parse('https://matrix.example.com');
      const channel = MethodChannel('flutter_web_auth_2');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => 'twake://done');
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final result = await host.ssoLoginActionMobile(context: context, id: 's');

      expect(result, SsoLoginState.tokenEmpty);
      expect(source.signIns, 0);
    });

    testWidgets('does not sign in at the Twake SSO when the homeserver does '
        'not take its id token', (tester) async {
      final source = _FakeTwakeSso(() async => tokens());
      final context = await pumpLogin(tester, source: source, jwtFlow: false);
      client.homeserver = Uri.parse('https://matrix.example.com');
      const channel = MethodChannel('flutter_web_auth_2');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => 'twake://done');
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final result = await host.ssoLoginActionMobile(context: context, id: 's');

      expect(result, SsoLoginState.tokenEmpty);
      expect(source.signIns, 0);
    });
  });

  testWidgets('a callback with no login token tells the user', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMatrixClientProvider.overrideWithValue(null),
          loginSessionsProvider.overrideWithValue(
            FakeLoginSessions(loginClient: () async => client),
          ),
        ],
        child: MaterialApp(
          navigatorKey: TwakeApp.routerKey,
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    client.homeserver = Uri.parse('https://matrix.example.com');
    const channel = MethodChannel('flutter_web_auth_2');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 'twake://done');
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final result = await host.ssoLoginActionMobile(
      context: tester.element(find.byType(Scaffold)),
      id: 'oidc',
    );
    await tester.pump();

    expect(result, SsoLoginState.tokenEmpty);
    final l10n = L10n.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
  });

  testWidgets('leaving the screen while the login client is pending does not '
      'start the login', (tester) async {
    final pending = Completer<Client>();
    var clientRequests = 0;
    // The screen the app shows: it is swapped for an empty one below, while
    // the app (and its navigator) stays.
    final screen = ValueNotifier<Widget>(const Scaffold(body: SizedBox()));
    addTearDown(screen.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMatrixClientProvider.overrideWithValue(null),
          loginSessionsProvider.overrideWithValue(
            // The web auth takes the client first; the login then waits for
            // the sessions (their cleanup retries) while the user leaves.
            FakeLoginSessions(
              loginClient: () =>
                  ++clientRequests == 1 ? Future.value(client) : pending.future,
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: TwakeApp.routerKey,
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          builder: (context, child) =>
              Provider<MatrixState>.value(value: matrix, child: child),
          home: ValueListenableBuilder<Widget>(
            valueListenable: screen,
            builder: (context, widget, _) => widget,
          ),
        ),
      ),
    );
    client.homeserver = Uri.parse('https://matrix.example.com');
    const channel = MethodChannel('flutter_web_auth_2');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => 'twake://done?loginToken=abc',
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final result = host.ssoLoginActionMobile(
      context: tester.element(find.byType(Scaffold)),
      id: 'oidc',
    );
    await tester.pump();
    expect(clientRequests, 2);

    screen.value = const SizedBox();
    await tester.pump();
    pending.complete(client);
    await tester.pump(const Duration(milliseconds: 100));

    // Without the check the login dialog opens over whatever is on screen and
    // the call waits for it, so the effects are read before the result.
    expect(client.logins, 0);
    expect(find.byType(InitClientDialog), findsNothing);
    expect(await result, SsoLoginState.error);
  });

  group('the web auth of the SSO fails', () {
    Future<(SsoLoginState, L10n)> failWith(
      WidgetTester tester,
      PlatformException error,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeMatrixClientProvider.overrideWithValue(null),
            loginSessionsProvider.overrideWithValue(
              FakeLoginSessions(loginClient: () async => client),
            ),
          ],
          child: MaterialApp(
            navigatorKey: TwakeApp.routerKey,
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      );
      client.homeserver = Uri.parse('https://matrix.example.com');
      const channel = MethodChannel('flutter_web_auth_2');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => throw error);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final context = tester.element(find.byType(Scaffold));
      final result = await host.ssoLoginActionMobile(
        context: context,
        id: 'oidc',
      );
      await tester.pump();
      return (result, L10n.of(context)!);
    }

    testWidgets('a cancel by the user stays silent', (tester) async {
      final (result, l10n) = await failWith(
        tester,
        PlatformException(code: 'CANCELED'),
      );

      expect(result, SsoLoginState.error);
      expect(find.text(l10n.oopsSomethingWentWrong), findsNothing);
    });

    testWidgets('any other error tells the user', (tester) async {
      final (result, l10n) = await failWith(
        tester,
        PlatformException(code: 'FAILED'),
      );

      expect(result, SsoLoginState.error);
      expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
    });
  });

  testWidgets('the system back does not close the dialog', (tester) async {
    await pumpApp(tester);
    final result = host.loginWithToken(sessions, client, 'token');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(InitClientDialog), findsOneWidget);

    // maybePop reports that it handled the request even when the route stays.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(InitClientDialog), findsOneWidget);

    matrix.onClientLoginStateChanged.add(loginFailed());
    await tester.pump(const Duration(seconds: 1));
    expect(await result, SsoLoginState.error);
    expect(find.byType(InitClientDialog), findsNothing);
  });

  testWidgets('a failure of another account leaves this dialog open', (
    tester,
  ) async {
    await pumpApp(tester);
    final result = host.loginWithToken(sessions, client, 'token');
    await tester.pump(const Duration(milliseconds: 100));

    final other = _FakeLoginClient();
    matrix.onClientLoginStateChanged.add(
      ClientLoginStateEvent(
        client: other,
        loginState: LoginState.loggedOut,
        multipleAccountLoginType: MultipleAccountLoginType.loginFailed,
        error: StateError('other'),
      ),
    );
    await tester.pump();
    expect(find.byType(InitClientDialog), findsOneWidget);

    matrix.onClientLoginStateChanged.add(loginFailed());
    await tester.pump(const Duration(seconds: 1));
    expect(await result, SsoLoginState.error);
    expect(find.byType(InitClientDialog), findsNothing);
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
