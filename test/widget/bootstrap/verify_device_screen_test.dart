import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_state.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_view_model.dart';
import 'package:twake_chat/pages/bootstrap/verify_device_option.dart';
import 'package:twake_chat/pages/bootstrap/verify_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    // `VerifyDeviceViewStyle.settingTitleStyle` reads
    // `LinagoraTextThemeExtension` (registered app-wide in `TwakeThemes`) —
    // without it the style getter silently falls back to null, letting the
    // option rows render at ambient (much larger) font size and overflow
    // their fixed-height rows.
    theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
    locale: const Locale('en'),
    localizationsDelegates: const [
      L10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: LocalizationService.supportedLocales,
    home: child,
  );
}

List<VerifyDeviceOption> _testOptions(BuildContext context) => [
  VerifyDeviceOption(
    icon: Icons.smartphone_outlined,
    title: L10n.of(context)!.useAnotherDevice,
    subtitle: '',
    isUseAnotherDevice: true,
  ),
  VerifyDeviceOption(
    icon: Icons.key_outlined,
    title: L10n.of(context)!.useRecoveryKeyTitle,
    subtitle: '',
    isUseRecoveryKey: true,
  ),
  VerifyDeviceOption(
    icon: Icons.key_off_outlined,
    title: L10n.of(context)!.notPossibleToVerify,
    subtitle: '',
    isNotPossibleToVerify: true,
  ),
];

Widget _buildScreen({
  required Client client,
  BootstrapUiState bootstrapState = const BootstrapVerifyDeviceState(),
  Future<bool> Function()? onResetEncryption,
}) {
  return ProviderScope(
    overrides: [
      bootstrapViewModelProvider(
        client,
        wipe: false,
      ).overrideWithValue(bootstrapState),
    ],
    child: Builder(
      builder: (context) => VerifyDeviceScreen(
        client: client,
        wipe: false,
        options: _testOptions(context),
        onResetEncryption: onResetEncryption ?? () async => false,
      ),
    ),
  );
}

/// Pumps [_buildScreen] at [size] (default: wide/web layout) and resets the
/// surface size on teardown — the setup every test below needs before its
/// own assertions and interactions.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required Client client,
  BootstrapUiState bootstrapState = const BootstrapVerifyDeviceState(),
  Future<bool> Function()? onResetEncryption,
  Size size = const Size(1024, 1400),
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);

  await tester.pumpWidget(
    _wrap(
      _buildScreen(
        client: client,
        bootstrapState: bootstrapState,
        onResetEncryption: onResetEncryption,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _rendersChooserByDefault(
  WidgetTester tester,
  Client client,
) async {
  await _pumpScreen(tester, client: client);

  expect(tester.takeException(), isNull);
  expect(find.text('Verify this device'), findsOneWidget);
  expect(find.text('Use another device'), findsOneWidget);
  expect(find.text('Use recovery key'), findsOneWidget);
  expect(find.text('Not possible to verify?'), findsOneWidget);
  expect(find.text('Retry automatically'), findsOneWidget);
}

Future<void> _tappingUseRecoveryKeyOpensForm(
  WidgetTester tester,
  Client client,
) async {
  await _pumpScreen(tester, client: client);

  await tester.tap(find.text('Use recovery key'));
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.text('Enter recovery key'), findsOneWidget);
  expect(find.text('Verify this device'), findsNothing);
}

Future<void> _tappingNotPossibleToVerifyOpensResetConfirm(
  WidgetTester tester,
  Client client,
) async {
  await _pumpScreen(tester, client: client);

  await tester.tap(find.text('Not possible to verify?'));
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.text('Reset end-to-end encryption'), findsOneWidget);

  await tester.tap(find.text('Cancel'));
  await tester.pump();

  expect(find.text('Verify this device'), findsOneWidget);
}

Future<void> _resetEncryptionSuccessShowsResetComplete(
  WidgetTester tester,
  Client client,
) async {
  await _pumpScreen(
    tester,
    client: client,
    onResetEncryption: () async => true,
  );

  await tester.tap(find.text('Not possible to verify?'));
  await tester.pump();
  await tester.tap(find.text('Reset'));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.text('Reset complete'), findsOneWidget);
}

Future<void> _retryFailedRendersRetryErrorView(
  WidgetTester tester,
  Client client,
) async {
  await _pumpScreen(
    tester,
    client: client,
    bootstrapState: const BootstrapVerifyDeviceState(retryFailed: true),
  );

  expect(tester.takeException(), isNull);
  expect(
    find.text(
      "Automatic retry didn't work. Try another way to verify this device.",
    ),
    findsOneWidget,
  );

  await tester.tap(find.text('Close'));
  await tester.pump();

  expect(find.text('Verify this device'), findsOneWidget);
}

Future<void> _retrySucceededRendersSuccessView(
  WidgetTester tester,
  Client client,
) async {
  await _pumpScreen(
    tester,
    client: client,
    bootstrapState: const BootstrapVerifyDeviceState(retrySucceeded: true),
  );

  expect(tester.takeException(), isNull);
  expect(find.text('Device verified'), findsOneWidget);
}

Future<void> _rendersInsideMobileBottomSheet(
  WidgetTester tester,
  Client client,
) async {
  await _pumpScreen(tester, client: client, size: const Size(430, 1400));

  expect(tester.takeException(), isNull);
  expect(find.text('Verify this device'), findsOneWidget);
  // Web-only close button (mobile relies on the sheet's own drag handle).
  expect(find.byIcon(Icons.close), findsNothing);
}

/// Exercises `VerifyDeviceScreen._buildContent`'s mapping from
/// `VerifyDeviceUiState` to the actual rendered widget — the part a pure
/// notifier unit test can't catch (e.g. a state added to the switch but
/// never wired to a view, or a view swapped for the wrong one). Complements
/// `test/pages/bootstrap/verify_device_view_model_test.dart`, which covers
/// the notifier's state-transition logic in isolation.
///
/// The `askSas`-driven states are out of scope here (as in the prior
/// widget-test suite): they need a live `KeyVerification`, which requires a
/// full `Encryption`+`Client` round-trip with no fake/mock available in the
/// SDK or this repo.
void main() {
  late Client client;

  setUpAll(() async {
    client = await getClient();
  });

  testWidgets(
    'renders the chooser by default',
    (tester) => _rendersChooserByDefault(tester, client),
  );

  testWidgets(
    'tapping "Use recovery key" opens the recovery-key form',
    (tester) => _tappingUseRecoveryKeyOpensForm(tester, client),
  );

  testWidgets(
    'tapping "Not possible to verify?" opens the reset-encryption confirm '
    'view, and Cancel returns to the chooser',
    (tester) => _tappingNotPossibleToVerifyOpensResetConfirm(tester, client),
  );

  testWidgets(
    'reset-encryption success shows the reset-complete view',
    (tester) => _resetEncryptionSuccessShowsResetComplete(tester, client),
  );

  testWidgets(
    'bootstrap retry-failed state renders the retry-error view, and '
    'dismissing it returns to the chooser',
    (tester) => _retryFailedRendersRetryErrorView(tester, client),
  );

  testWidgets(
    'bootstrap retry-succeeded state renders the success view',
    (tester) => _retrySucceededRendersSuccessView(tester, client),
  );

  testWidgets(
    'renders inside a mobile bottom sheet on narrow screens',
    (tester) => _rendersInsideMobileBottomSheet(tester, client),
  );
}
