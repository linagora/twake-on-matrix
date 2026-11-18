import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/encryption.dart';
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
  _FakeMatrix(this.client);

  @override
  final Client client;

  @override
  bool get twakeSupported => false;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

/// Drives the real [Settings] screen on top of the fakes above.
class _SettingsScreen {
  const _SettingsScreen(this.tester);

  final WidgetTester tester;

  Future<void> pump(Client client) async {
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

  testWidgets('a check started after dispose does nothing', (tester) async {
    expect(await _SettingsScreen(tester).checkAfterClose(), isEmpty);
  });
}
