import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/login/login.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/widgets/matrix.dart';
import '../../providers/fake_login_sessions.dart';

class _FakeLoginClient extends Fake implements Client {
  int logins = 0;

  _FakeLoginClient({this.homeserver});

  @override
  Uri? homeserver;

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
  _FakeMatrixState(this.loginClient);

  final _FakeLoginClient loginClient;

  /// What `getLoginClient` returns after the first call: a fresh client that
  /// has no homeserver, as one signed out by the SDK has.
  final retryClient = _FakeLoginClient();
  int loginClientRequests = 0;

  @override
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController<ClientLoginStateEvent>.broadcast();

  @override
  String? loginType;

  @override
  Future<Client> getLoginClient() async {
    return loginClientRequests++ == 0 ? loginClient : retryClient;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

void main() {
  late _FakeLoginClient client;
  late _FakeMatrixState matrix;
  late FakeLoginSessions sessions;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    client = _FakeLoginClient(homeserver: Uri.parse('https://example.com'));
    matrix = _FakeMatrixState(client);
    sessions = FakeLoginSessions(loginClient: matrix.getLoginClient);
    TwakeDialog.responsiveUtils = getIt.get<ResponsiveUtils>();
  });

  tearDown(() async {
    await matrix.onClientLoginStateChanged.close();
    await GetIt.I.reset();
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [loginSessionsProvider.overrideWithValue(sessions)],
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Provider<MatrixState>.value(
            value: matrix,
            child: const Login(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> submitLogin(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'alice');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(milliseconds: 100));
  }

  ClientLoginStateEvent loginFailed({
    MultipleAccountLoginType type = MultipleAccountLoginType.loginFailed,
  }) => ClientLoginStateEvent(
    client: client,
    loginState: LoginState.loggedOut,
    multipleAccountLoginType: type,
    error: StateError('the store is full'),
  );

  testWidgets('a failed registration hides the dialog and shows the error', (
    tester,
  ) async {
    await pumpLogin(tester);
    await submitLogin(tester);
    expect(find.byType(ProgressDialog), findsOneWidget);

    matrix.onClientLoginStateChanged.add(loginFailed());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ProgressDialog), findsNothing);
    final l10n = L10n.of(tester.element(find.byType(Login)))!;
    expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);
    expect(find.text('the store is full'), findsNothing);
  });

  testWidgets(
    'the user can log in again, on a fresh client that has the homeserver',
    (tester) async {
      await pumpLogin(tester);
      await submitLogin(tester);
      expect(client.logins, 1);
      final requestsBefore = matrix.loginClientRequests;

      matrix.onClientLoginStateChanged.add(loginFailed());
      await tester.pump(const Duration(seconds: 1));
      expect(matrix.loginClientRequests, requestsBefore + 1);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(matrix.retryClient.logins, 1);
      expect(matrix.retryClient.homeserver, Uri.parse('https://example.com'));
      expect(find.byType(ProgressDialog), findsOneWidget);
    },
  );

  testWidgets('a failure of another client is ignored', (tester) async {
    await pumpLogin(tester);
    await submitLogin(tester);

    matrix.onClientLoginStateChanged.add(
      ClientLoginStateEvent(
        client: _FakeLoginClient(),
        loginState: LoginState.loggedOut,
        multipleAccountLoginType: MultipleAccountLoginType.loginFailed,
        error: StateError('other'),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ProgressDialog), findsOneWidget);
  });

  testWidgets(
    'a cleanup that failed is shown like a failed login, and the user can try again',
    (tester) async {
      await pumpLogin(tester);
      await submitLogin(tester);

      matrix.onClientLoginStateChanged.add(
        loginFailed(type: MultipleAccountLoginType.cleanupFailed),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ProgressDialog), findsNothing);
      final l10n = L10n.of(tester.element(find.byType(Login)))!;
      expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(matrix.retryClient.logins, 1);
    },
  );
}
