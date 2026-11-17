import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

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

  @override
  final CachedStreamController<BasicEvent> onAccountData =
      CachedStreamController();
}

class _FakeMatrix extends Fake implements MatrixState {
  _FakeMatrix(this.client);

  @override
  final Client client;

  @override
  bool get twakeSupported => false;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

void main() {
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpSettings(WidgetTester tester, Client client) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Provider<MatrixState>.value(
          value: _FakeMatrix(client),
          child: MaterialApp(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: const Settings(),
          ),
        ),
      ),
    );
  }

  /// Starts a second backup check that waits on the returned completer.
  ///
  /// The check is an `async void`: its error reaches the zone that starts it,
  /// so that zone records what it throws. The completer is created in the same
  /// zone, because an error does not cross into another error zone.
  Future<({Completer<void> accountData, List<Object> errors})> startHeldCheck(
    WidgetTester tester,
  ) async {
    final client = _FakeClient();
    await pumpSettings(tester, client);
    await tester.pump();

    late final Completer<void> accountData;
    final errors = <Object>[];
    runZonedGuarded(() {
      accountData = Completer<void>();
      client.accountDataLoading = accountData.future;
      tester.state<SettingsController>(find.byType(Settings)).checkBootstrap();
    }, (error, _) => errors.add(error));
    return (accountData: accountData, errors: errors);
  }

  void expectSwitchOffAndNoLoadingTile(WidgetTester tester) {
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  testWidgets('the loading tile shows until the backup check has run', (
    tester,
  ) async {
    await pumpSettings(tester, _FakeClient());

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
  });

  testWidgets('encryption disabled: the check ends, the switch is off', (
    tester,
  ) async {
    await pumpSettings(tester, _FakeClient());
    await tester.pump();
    await tester.pump();

    expectSwitchOffAndNoLoadingTile(tester);
  });

  testWidgets('the check fails: the error surfaces, the switch is off', (
    tester,
  ) async {
    final error = StateError('account data');
    final check = await startHeldCheck(tester);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    check.accountData.completeError(error);
    await tester.pump();

    expect(check.errors, [error]);
    expectSwitchOffAndNoLoadingTile(tester);
  });

  testWidgets('the screen is disposed during the check: only the error of '
      'the check surfaces', (tester) async {
    final error = StateError('account data');
    final check = await startHeldCheck(tester);

    await tester.pumpWidget(const SizedBox());
    check.accountData.completeError(error);
    await tester.pump();

    expect(check.errors, [error]);
  });
}
