import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/twake_welcome/twake_welcome.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

import '../../providers/fake_login_sessions.dart';

const _webAuth = MethodChannel('flutter_web_auth_2');

class _FakeClient extends Fake implements Client {
  /// The error of the homeserver check; none gives a home server.
  Object? homeserverError;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName != #checkHomeserver) {
      return super.noSuchMethod(invocation);
    }
    if (homeserverError != null) return Future<Never>.error(homeserverError!);
    return Future.value((
      null,
      GetVersionsResponse(versions: const []),
      const <LoginFlow>[],
      null,
    ));
  }
}

class _FakeMatrixState extends Fake implements MatrixState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

void main() {
  late _FakeClient client;
  late FakeLoginSessions sessions;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    client = _FakeClient();
    sessions = FakeLoginSessions(loginClient: () async => client);
    TwakeApp.routerKey = GlobalKey<NavigatorState>();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_webAuth, null);
    await GetIt.I.reset();
  });

  void webAuthThrows(String code) => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(
        _webAuth,
        (_) async => throw PlatformException(code: code),
      );

  Future<void> pumpApp(WidgetTester tester, Widget home) => tester.pumpWidget(
    ProviderScope(
      overrides: [loginSessionsProvider.overrideWithValue(sessions)],
      child: MaterialApp(
        navigatorKey: TwakeApp.routerKey,
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder: (context, child) => Provider<MatrixState>.value(
          value: _FakeMatrixState(),
          child: child,
        ),
        home: home,
      ),
    ),
  );

  Future<void> signIn(WidgetTester tester) async {
    await pumpApp(tester, const TwakeWelcome(arg: TwakeWelcomeArg()));
    tester
        .state<TwakeWelcomeController>(find.byType(TwakeWelcome))
        .onClickSignIn();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  String failedText(WidgetTester tester) => L10n.of(
    tester.element(find.byType(TwakeWelcome)),
  )!.oopsSomethingWentWrong;

  testWidgets('leaving the welcome screen drops the candidate', (tester) async {
    await pumpApp(tester, const TwakeWelcome(arg: TwakeWelcomeArg()));
    expect(sessions.discards, 0);

    await pumpApp(tester, const SizedBox());

    expect(sessions.discards, 1);
  });

  testWidgets('a sign-in cancelled by the user stays silent and drops the '
      'candidate', (tester) async {
    webAuthThrows('CANCELED');

    await signIn(tester);

    expect(find.text(failedText(tester)), findsNothing);
    expect(sessions.discards, 1);
  });

  testWidgets('a sign-in that fails tells the user and drops the candidate', (
    tester,
  ) async {
    webAuthThrows('FAILED');

    await signIn(tester);

    expect(find.text(failedText(tester)), findsOneWidget);
    expect(sessions.discards, 1);
  });

  testWidgets('a home server that cannot be checked tells the user', (
    tester,
  ) async {
    client.homeserverError = StateError('homeserver down');

    await signIn(tester);

    expect(find.text(failedText(tester)), findsOneWidget);
    expect(sessions.discards, 1);
  });

  testWidgets('a sign-in that ends after the user left does nothing more', (
    tester,
  ) async {
    final auth = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_webAuth, (_) => auth.future);
    await signIn(tester);

    await pumpApp(tester, const SizedBox());
    expect(sessions.discards, 1);
    auth.complete('twake.chat://redirect');
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
