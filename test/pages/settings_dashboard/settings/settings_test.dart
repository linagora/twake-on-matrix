import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/providers/twake_supported_provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

/// A client with no user: the profile lookup is skipped, only the backup check
/// runs. Without [accountDataLoading] encryption is off and the check ends
/// without a result; with it the check waits on that future.
class _FakeClient extends Fake implements Client {
  @override
  Future<void>? accountDataLoading;

  @override
  bool get encryptionEnabled => accountDataLoading != null;

  @override
  String? get userID => null;

  // What the check reads once [accountDataLoading] completes: a synced client
  // with no keys, on a session nobody verified.
  @override
  Future<void>? get userDeviceKeysLoading => null;

  @override
  String? get prevBatch => 'batch';

  @override
  Encryption? get encryption => null;

  @override
  bool get isUnknownSession => true;

  @override
  final CachedStreamController<BasicEvent> onAccountData =
      CachedStreamController();
}

class _FakeMatrix extends Fake implements MatrixState {
  _FakeMatrix(this.client, {this.loginType, this.authUrl});

  @override
  final Client client;

  @override
  String? loginType;

  @override
  final String? authUrl;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

/// Drives the real [Settings] screen on top of the fakes above.
class _SettingsScreen {
  _SettingsScreen(this.tester);

  final WidgetTester tester;

  Client? _active;
  late MatrixState _matrix;

  Future<void> pump(Client client) async {
    _active = client;
    _matrix = _FakeMatrix(client);
    await pumpScreen(const Settings());
  }

  Future<void> pumpScreen(Settings settings) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMatrixClientProvider.overrideWith((ref) => _active),
          twakeSupportedProvider.overrideWithValue(false),
        ],
        child: Provider<MatrixState>.value(
          value: _matrix,
          child: MaterialApp(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: settings,
          ),
        ),
      ),
    );
  }

  /// The last logout drops the client while the screen is still mounted.
  Future<void> dropClient() async {
    _active = null;
    ProviderScope.containerOf(
      tester.element(find.byType(Settings)),
    ).invalidate(activeMatrixClientProvider);
    await tester.pump();
  }

  /// Starts a second backup check that waits on the returned completer, and
  /// expects the loading tile while it runs.
  ///
  /// The check is an `async void`: its error reaches the zone that starts it,
  /// so that zone records what it throws. The completer is created in the same
  /// zone, because an error does not cross into another error zone.
  Future<({Completer<void> accountData, List<Object> errors})>
  startHeldCheck() async {
    final client = _FakeClient();
    await pump(client);
    await tester.pump();

    late final Completer<void> accountData;
    final errors = <Object>[];
    runZonedGuarded(() {
      accountData = Completer<void>();
      client.accountDataLoading = accountData.future;
      tester.state<SettingsController>(find.byType(Settings)).checkBootstrap();
    }, (error, _) => errors.add(error));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    return (accountData: accountData, errors: errors);
  }

  void expectSwitchOffAndNoLoadingTile() {
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isFalse);
    expect(tile.onChanged, isNull, reason: 'unknown state: no tap action');
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  /// Closes the screen while a check is held, then ends the check, with
  /// [error] when given. Returns what the check threw.
  Future<List<Object>> closeDuringCheck([Object? error]) async {
    final check = await startHeldCheck();
    await tester.pumpWidget(const SizedBox());
    error == null
        ? check.accountData.complete()
        : check.accountData.completeError(error);
    await tester.pump();
    return check.errors;
  }

  /// Starts a check on a screen that is already closed. Returns what it threw.
  Future<List<Object>> checkAfterClose() async {
    await pump(_FakeClient());
    final controller = tester.state<SettingsController>(find.byType(Settings));
    await tester.pumpWidget(const SizedBox());

    final errors = <Object>[];
    runZonedGuarded(controller.checkBootstrap, (e, _) => errors.add(e));
    await tester.pump();
    return errors;
  }
}

/// The last account: its logout lands the app on the welcome page, so the
/// Settings page is gone before the logout flow ends.
class _LastAccountClient extends _FakeClient {
  _LastAccountClient(this.onLogout);

  final void Function() onLogout;

  @override
  String get clientName => 'last-account';

  // The race of the review: the app goes to the welcome page on the logged
  // out state, while the rest of the cleanup still runs, and ends once the
  // welcome page covers Settings and Settings is unmounted.
  @override
  Future<void> logout() async {
    onLogout();
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

/// The app with its router: Settings on top of a welcome page. Logging out
/// the last account goes to the welcome page, as `MatrixState` does, which
/// removes Settings and the dialogs shown above it.
class _LogoutFlow {
  _LogoutFlow(this.tester);

  final WidgetTester tester;

  /// The URLs the SSO sign-out opened in the browser.
  final opened = <String>[];

  /// The failures the logout reported.
  final failures = <Object>[];

  /// What the logout threw outside the flow. The router removes the loading
  /// dialog with Settings, and `future_loading_dialog` then reads its own
  /// unmounted context: a separate defect of the same race, kept here so it
  /// does not decide the specs of the SSO sign-out.
  final uncaught = <Object>[];

  Future<void> logOut({String? loginType, String? authUrl}) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const webAuth = MethodChannel('flutter_web_auth_2');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(webAuth, (call) async {
      if (call.method == 'authenticate') {
        opened.add((call.arguments as Map)['url'] as String);
        return 'twake://redirect';
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(webAuth, null));

    // As in the app: Settings lives under the rooms, the welcome page under
    // home, two separate trees with the desktop fade page.
    Page<void> page(Widget child) => CustomTransitionPage(
      child: child,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    final router = GoRouter(
      navigatorKey: TwakeApp.routerKey,
      initialLocation: '/rooms/settings',
      routes: [
        GoRoute(
          path: '/rooms',
          pageBuilder: (_, _) => page(const Scaffold(body: Text('rooms'))),
          routes: [
            GoRoute(
              path: 'settings',
              pageBuilder: (_, _) => page(const Settings()),
            ),
          ],
        ),
        GoRoute(
          path: '/home/twakeWelcome',
          pageBuilder: (_, _) => page(const Scaffold(body: Text('welcome'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    final client = _LastAccountClient(() => router.go('/home/twakeWelcome'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMatrixClientProvider.overrideWith((ref) => client),
          twakeSupportedProvider.overrideWithValue(false),
          reportFailureProvider.overrideWithValue(
            (error, _, _) => failures.add(error),
          ),
        ],
        child: Provider<MatrixState>.value(
          value: _FakeMatrix(client, loginType: loginType, authUrl: authUrl),
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final l10n = L10n.of(tester.element(find.byType(Settings)))!;
    // The logout is an `async void` started by the tap, and the loading
    // dialog starts its own work while a frame builds: their errors reach
    // the zone of the taps and pumps below.
    await runZonedGuarded(() async {
      await tester.tap(find.text(l10n.logout));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      // The confirmation dialog: its button carries the same label.
      await tester.tap(find.text(l10n.logout).last);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }, (error, _) => uncaught.add(error));
  }
}

void main() {
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDown(() => GetIt.instance.reset());

  testWidgets('the loading tile shows while the check runs', (tester) async {
    await _SettingsScreen(tester).pump(_FakeClient());

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
  });

  testWidgets('encryption disabled: the switch is off', (tester) async {
    await _SettingsScreen(tester).pump(_FakeClient());
    await tester.pump();
    await tester.pump();

    _SettingsScreen(tester).expectSwitchOffAndNoLoadingTile();
  });

  testWidgets('a failed check: an error, the switch is off', (tester) async {
    final error = StateError('account data');
    final check = await _SettingsScreen(tester).startHeldCheck();

    check.accountData.completeError(error);
    await tester.pump();

    expect(check.errors, [error]);
    _SettingsScreen(tester).expectSwitchOffAndNoLoadingTile();
  });

  testWidgets('a check that never ends: the switch is off', (tester) async {
    final screen = _SettingsScreen(tester);
    final check = await screen.startHeldCheck();

    await tester.pump(SettingsController.backupCheckTimeout);
    await tester.pump();

    expect(check.errors, isEmpty);
    screen.expectSwitchOffAndNoLoadingTile();
  });

  testWidgets('disposed during a check: only its error', (tester) async {
    final error = StateError('account data');
    expect(await _SettingsScreen(tester).closeDuringCheck(error), [error]);
  });

  testWidgets('disposed during a check that ends: no error', (tester) async {
    expect(await _SettingsScreen(tester).closeDuringCheck(), isEmpty);
  });

  testWidgets('the client dropped while mounted: nothing is shown', (
    tester,
  ) async {
    final screen = _SettingsScreen(tester);
    await screen.pump(_FakeClient());
    await tester.pump();

    await screen.dropClient();

    expect(tester.takeException(), isNull);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the client dropped while mounted: a check does nothing', (
    tester,
  ) async {
    final screen = _SettingsScreen(tester);
    await screen.pump(_FakeClient());
    await tester.pump();
    await screen.dropClient();

    final errors = <Object>[];
    runZonedGuarded(
      tester.state<SettingsController>(find.byType(Settings)).checkBootstrap,
      (e, _) => errors.add(e),
    );
    await tester.pump();

    expect(errors, isEmpty);
  });

  testWidgets('the client dropped while mounted: a widget update is safe', (
    tester,
  ) async {
    final screen = _SettingsScreen(tester);
    await screen.pump(_FakeClient());
    await tester.pump();
    await screen.dropClient();

    await screen.pumpScreen(Settings(bottomNavigationBar: Container()));

    expect(tester.takeException(), isNull);
  });

  testWidgets('a check started after dispose does nothing', (tester) async {
    expect(await _SettingsScreen(tester).checkAfterClose(), isEmpty);
  });

  group('logout from Settings with an SSO login', () {
    const authUrl = 'https://sso.example.com/oauth2/authorize';

    testWidgets('signs out at the SSO although Settings is already gone', (
      tester,
    ) async {
      final flow = _LogoutFlow(tester);

      await flow.logOut(loginType: LoginType.mLoginToken, authUrl: authUrl);

      expect(find.byType(Settings), findsNothing);
      expect(find.text('welcome'), findsOneWidget);
      expect(flow.opened, ['$authUrl?logout=1']);
      expect(flow.failures, isEmpty);
    });

    testWidgets('a login without SSO opens no browser', (tester) async {
      final flow = _LogoutFlow(tester);

      await flow.logOut(authUrl: authUrl);

      expect(find.text('welcome'), findsOneWidget);
      expect(flow.opened, isEmpty);
    });
  });
}
