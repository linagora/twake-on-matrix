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
import 'package:twake_chat/pages/login/login_client_owner.dart';
import 'package:twake_chat/pages/login/login.dart';
import 'package:twake_chat/domain/account/entities/client_login_state_event.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/widgets/matrix.dart';
import '../../providers/fake_login_sessions.dart';

class _FakeClient extends Fake implements Client {
  @override
  Uri? get homeserver => Uri.parse('https://example.com');
}

class _FakeMatrixState extends Fake implements MatrixState {
  final _client = _FakeClient();

  @override
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController<ClientLoginStateEvent>.broadcast();

  @override
  Future<Client> getLoginClient() async => _client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

void main() {
  late _FakeMatrixState matrix;
  late FakeLoginSessions sessions;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    matrix = _FakeMatrixState();
    sessions = FakeLoginSessions(loginClient: matrix.getLoginClient);
  });

  tearDown(() async {
    await matrix.onClientLoginStateChanged.close();
    await GetIt.I.reset();
  });

  Future<void> pumpApp(WidgetTester tester, Widget home) => tester.pumpWidget(
    ProviderScope(
      overrides: [loginSessionsProvider.overrideWithValue(sessions)],
      child: MaterialApp(
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder: (context, child) =>
            Provider<MatrixState>.value(value: matrix, child: child),
        home: home,
      ),
    ),
  );

  Future<void> bigScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('a login page that owns the candidate drops it on exit', (
    tester,
  ) async {
    await bigScreen(tester);
    await pumpApp(tester, const Login());
    await tester.pump();
    expect(sessions.discards, 0);

    await pumpApp(tester, const SizedBox());

    expect(sessions.discards, 1);
  });

  testWidgets(
    'a login page pushed by the owner of the candidate leaves it to the owner',
    (tester) async {
      await bigScreen(tester);
      await pumpApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Login(owner: LoginClientOwner.caller),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(Login), findsOneWidget);

      Navigator.of(tester.element(find.byType(Login))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(Login), findsNothing);
      expect(sessions.discards, 0);
    },
  );
}
