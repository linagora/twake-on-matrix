import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/login/login.dart';
import 'package:twake_chat/presentation/model/client_login_state_event.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
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

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    matrix = _FakeMatrixState();
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
        overrides: [
          loginSessionsProvider.overrideWithValue(
            FakeLoginSessions(loginClient: matrix.getLoginClient),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          builder: (context, child) =>
              Provider<MatrixState>.value(value: matrix, child: child),
          home: const Login(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectDimmedHint(WidgetTester tester, String label, String hint) {
    final field = find.ancestor(
      of: find.text(label),
      matching: find.byType(TextField),
    );
    final hintFinder = find.descendant(of: field, matching: find.text(hint));
    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(of: hintFinder, matching: find.byType(AnimatedOpacity)),
    );
    final valueStyle = tester
        .widget<EditableText>(
          find.descendant(of: field, matching: find.byType(EditableText)),
        )
        .style;
    expect(opacity.opacity, 1);
    expect(tester.widget<Text>(hintFinder).style?.color, isNotNull);
    expect(
      tester.widget<Text>(hintFinder).style?.color,
      isNot(valueStyle.color),
    );
  }

  testWidgets('build_emptyUnfocusedPassword_showsLabelAndDimmedHint', (
    tester,
  ) async {
    // Act
    await pumpLogin(tester);

    // Assert
    expect(find.text('Password'), findsOneWidget);
    expectDimmedHint(tester, 'Password', 'Please enter your password');
  });

  testWidgets('build_emptyUnfocusedUsername_showsLabelAndDimmedHint', (
    tester,
  ) async {
    // Arrange
    await pumpLogin(tester);

    // Act
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Matrix Id or username'), findsOneWidget);
    expectDimmedHint(
      tester,
      'Matrix Id or username',
      'Please enter your Matrix Id or username',
    );
  });
}
