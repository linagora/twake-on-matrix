import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/login/login.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _FakeClient extends Fake implements Client {
  @override
  Uri? get homeserver => Uri.parse('https://example.com');
}

class _FakeMatrixState extends Fake implements MatrixState {
  final _client = _FakeClient();
  int discards = 0;

  @override
  final StreamController<ClientLoginStateEvent> onClientLoginStateChanged =
      StreamController<ClientLoginStateEvent>.broadcast();

  @override
  Future<Client> getLoginClient() async => _client;

  @override
  Future<void> discardPendingLoginCandidate() async => discards++;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

void main() {
  late _FakeMatrixState matrix;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    matrix = _FakeMatrixState();
  });

  tearDown(() async {
    await matrix.onClientLoginStateChanged.close();
    await GetIt.I.reset();
  });

  Widget app(Widget home) => MaterialApp(
    theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    builder: (context, child) =>
        Provider<MatrixState>.value(value: matrix, child: child),
    home: home,
  );

  Future<void> bigScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('a login page that starts the flow drops the candidate on exit', (
    tester,
  ) async {
    await bigScreen(tester);
    await tester.pumpWidget(app(const Login()));
    await tester.pump();
    expect(matrix.discards, 0);

    await tester.pumpWidget(app(const SizedBox()));

    expect(matrix.discards, 1);
  });

  testWidgets(
    'a login page on top of another page leaves the candidate to it',
    (tester) async {
      await bigScreen(tester);
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const Login())),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(Login), findsOneWidget);

      Navigator.of(tester.element(find.byType(Login))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(Login), findsNothing);
      expect(matrix.discards, 0);
    },
  );
}
