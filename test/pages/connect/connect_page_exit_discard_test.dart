import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/connect/connect_page.dart';
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
  HomeserverSummary? get loginHomeserverSummary => null;

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

  tearDown(() => GetIt.I.reset());

  Widget app(Widget home) => MaterialApp(
    theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    builder: (context, child) => ProviderScope(
      overrides: [
        loginHostSlotProvider.overrideWithValue(FakeLoginHostSlot(sessions)),
      ],
      child: Provider<MatrixState>.value(value: matrix, child: child),
    ),
    home: home,
  );

  testWidgets(
    'a connect page that starts the flow drops the candidate on exit',
    (tester) async {
      await tester.pumpWidget(app(const ConnectPage()));
      await tester.pump();
      expect(sessions.discards, 0);

      await tester.pumpWidget(app(const SizedBox()));

      expect(sessions.discards, 1);
    },
  );

  testWidgets(
    'a connect page on top of another page leaves the candidate to it',
    (tester) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ConnectPage()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ConnectPage), findsOneWidget);

      Navigator.of(tester.element(find.byType(ConnectPage))).pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(sessions.discards, 0);
    },
  );
}
