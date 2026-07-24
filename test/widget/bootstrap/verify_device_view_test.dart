import 'dart:async';

import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_option.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/encryption.dart';

Widget _wrap(Widget child, {double? width}) {
  final app = MaterialApp(
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
  // `tester.binding.setSurfaceSize` doesn't reliably flow into
  // `MediaQuery.sizeOf` for every widget under test, so force it directly
  // when a test needs to pin web-vs-mobile chrome ([ResponsiveUtils]
  // branches on `MediaQuery.sizeOf(context).width`).
  if (width == null) return app;
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 1400)),
    child: app,
  );
}

List<VerifyDeviceOption> _testOptions(BuildContext context) => [
  VerifyDeviceOption(
    icon: Icons.smartphone_outlined,
    title: L10n.of(context)!.useAnotherDevice,
    subtitle: L10n.of(context)!.useAnotherDeviceDescription,
    isUseAnotherDevice: true,
  ),
  VerifyDeviceOption(
    icon: Icons.key_outlined,
    title: L10n.of(context)!.useRecoveryKeyTitle,
    subtitle: L10n.of(context)!.useRecoveryKeyDescription,
    isUseRecoveryKey: true,
  ),
  VerifyDeviceOption(
    icon: Icons.key_off_outlined,
    title: L10n.of(context)!.notPossibleToVerify,
    subtitle: L10n.of(context)!.notPossibleToVerifyDescription,
    isNotPossibleToVerify: true,
  ),
];

void main() {
  group('chooser content', _chooserContentTests);
  group('start verification', _startVerificationTests);
  group('recovery key flow', _recoveryKeyFlowTests);
  group('reset encryption flow', _resetEncryptionFlowTests);
  group('initial state', _initialStateTests);
  group('retry', _retryTests);
}

void _chooserContentTests() {
  testWidgets('VerifyDeviceScreen renders web modal content', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1024, 1400));

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) =>
              VerifyDeviceScreen(options: _testOptions(context)),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Verify this device'), findsOneWidget);
    expect(find.text('Use another device'), findsOneWidget);
    expect(find.text('Use recovery key'), findsOneWidget);
    expect(find.text('Not possible to verify?'), findsOneWidget);
    expect(find.text('Retry automatically'), findsOneWidget);
  });

  testWidgets('VerifyDeviceScreen renders mobile sheet content', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 1400));

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) =>
              VerifyDeviceScreen(options: _testOptions(context)),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Verify this device'), findsOneWidget);
    expect(find.text('Use another device'), findsOneWidget);
    expect(find.text('Use recovery key'), findsOneWidget);
    expect(find.text('Not possible to verify?'), findsOneWidget);
    expect(find.text('Retry automatically'), findsOneWidget);
  });
}

void _startVerificationTests() {
  testWidgets(
    'VerifyDeviceScreen invokes onStartVerification when '
    '"Use another device" is tapped',
    _startVerificationInvokesCallback,
  );
  testWidgets(
    'VerifyDeviceScreen shows a loading spinner and blocks re-tap while '
    'onStartVerification is in flight',
    _startVerificationShowsLoadingAndBlocksRetap,
  );
  testWidgets(
    'VerifyDeviceScreen stays on chooser when onStartVerification '
    'resolves to null',
    _startVerificationStaysOnChooserWhenNull,
  );
}

Future<void> _startVerificationInvokesCallback(WidgetTester tester) async {
  var startVerificationCalled = false;

  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => VerifyDeviceScreen(
          options: _testOptions(context),
          onStartVerification: () async {
            startVerificationCalled = true;
            return null;
          },
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Use another device'));
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(startVerificationCalled, isTrue);
}

Future<void> _startVerificationShowsLoadingAndBlocksRetap(
  WidgetTester tester,
) async {
  var startVerificationCallCount = 0;
  final completer = Completer<KeyVerification?>();

  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => VerifyDeviceScreen(
          options: _testOptions(context),
          onStartVerification: () {
            startVerificationCallCount++;
            return completer.future;
          },
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Use another device'));
  await tester.pump();

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));

  // Tapping again while in flight must not call onStartVerification a
  // second time (row + button are both disabled while loading).
  await tester.tap(find.text('Use another device'));
  await tester.pump();
  expect(startVerificationCallCount, 1);

  completer.complete(null);
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
}

Future<void> _startVerificationStaysOnChooserWhenNull(
  WidgetTester tester,
) async {
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => VerifyDeviceScreen(
          options: _testOptions(context),
          onStartVerification: () async => null,
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Use another device'));
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.text('Verify this device'), findsOneWidget);
  expect(find.text('Use another device'), findsOneWidget);
}

void _recoveryKeyFlowTests() {
  testWidgets(
    'VerifyDeviceScreen shows recovery key form when '
    '"Use recovery key" is tapped, and X closes back to chooser '
    '(web modal only)',
    _recoveryKeyFormOpensAndClosesViaX,
  );
  testWidgets(
    'VerifyDeviceScreen shows error text when onVerifyRecoveryKey '
    'resolves to false',
    _recoveryKeyShowsErrorWhenInvalid,
  );
  testWidgets(
    'VerifyDeviceScreen shows required error and does not call '
    'onVerifyRecoveryKey when Verify is tapped with an empty field',
    _recoveryKeyShowsRequiredErrorWhenEmpty,
  );
  testWidgets(
    'VerifyDeviceScreen shows success view and pops on Start chatting '
    'when onVerifyRecoveryKey resolves to true',
    _recoveryKeyShowsSuccessAndPops,
  );
}

Future<void> _recoveryKeyFormOpensAndClosesViaX(WidgetTester tester) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(1024, 1400));

  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) =>
            VerifyDeviceScreen(options: _testOptions(context)),
      ),
      width: 1024,
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Use recovery key'));
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.text('Enter recovery key…'), findsOneWidget);
  expect(find.text('Verify'), findsOneWidget);

  await tester.tap(find.byIcon(Icons.close));
  await tester.pump();

  expect(find.text('Verify this device'), findsOneWidget);
}

Future<void> _recoveryKeyShowsErrorWhenInvalid(WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => VerifyDeviceScreen(
          options: _testOptions(context),
          onVerifyRecoveryKey: (_) async => false,
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Use recovery key'));
  await tester.pump();
  await tester.enterText(find.byType(TextField), 'wrong-key');
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.text("Recovery key doesn't match"), findsOneWidget);
}

Future<void> _recoveryKeyShowsRequiredErrorWhenEmpty(
  WidgetTester tester,
) async {
  var verifyCalled = false;

  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => VerifyDeviceScreen(
          options: _testOptions(context),
          onVerifyRecoveryKey: (_) async {
            verifyCalled = true;
            return true;
          },
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Use recovery key'));
  await tester.pump();
  await tester.tap(find.text('Verify'));
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(verifyCalled, isFalse);
  expect(find.text('Recovery key is required'), findsOneWidget);
}

Future<void> _recoveryKeyShowsSuccessAndPops(WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => VerifyDeviceScreen(
            options: _testOptions(context),
            onVerifyRecoveryKey: (_) async => true,
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Use recovery key'));
  await tester.pump();
  await tester.enterText(find.byType(TextField), 'correct-key');
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.text('Device verified'), findsOneWidget);

  await tester.tap(find.text('Start chatting'));
  await tester.pumpAndSettle();

  expect(find.text('Device verified'), findsNothing);
}

void _resetEncryptionFlowTests() {
  testWidgets(
    'VerifyDeviceScreen shows reset confirm view when '
    '"Not possible to verify?" is tapped, and Cancel closes back to chooser',
    _resetConfirmClosesViaCancel,
  );
  testWidgets(
    'VerifyDeviceScreen shows reset confirm view when "Not possible to '
    'verify?" is tapped, and the modal\'s own X closes back to chooser '
    '(web modal only)',
    _resetConfirmClosesViaX,
  );
  testWidgets(
    'VerifyDeviceScreen shows a loading spinner on Reset and blocks '
    'Cancel/re-tap while onResetEncryption is in flight',
    _resetEncryptionShowsLoadingAndBlocksActions,
  );
  testWidgets(
    'VerifyDeviceScreen returns to chooser when onResetEncryption '
    'resolves to false',
    _resetEncryptionReturnsToChooserWhenFalse,
  );
  testWidgets(
    'VerifyDeviceScreen shows reset-complete view and pops on Start '
    'chatting when onResetEncryption resolves to true',
    _resetEncryptionShowsCompleteAndPops,
  );
}

Future<void> _resetConfirmClosesViaCancel(WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) =>
            VerifyDeviceScreen(options: _testOptions(context)),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Not possible to verify?'));
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.text('Reset end-to-end encryption'), findsOneWidget);
  expect(find.text('Reset'), findsOneWidget);
  expect(find.text('Cancel'), findsOneWidget);

  await tester.tap(find.text('Cancel'));
  await tester.pump();

  expect(find.text('Verify this device'), findsOneWidget);
}

Future<void> _resetConfirmClosesViaX(WidgetTester tester) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(1024, 1400));

  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) =>
            VerifyDeviceScreen(options: _testOptions(context)),
      ),
      width: 1024,
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Not possible to verify?'));
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.text('Reset end-to-end encryption'), findsOneWidget);
  expect(find.byIcon(Icons.close), findsOneWidget);

  await tester.tap(find.byIcon(Icons.close));
  await tester.pump();

  expect(find.text('Verify this device'), findsOneWidget);
}

Future<void> _resetEncryptionShowsLoadingAndBlocksActions(
  WidgetTester tester,
) async {
  var resetCallCount = 0;
  final completer = Completer<bool>();

  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => VerifyDeviceScreen(
          options: _testOptions(context),
          onResetEncryption: () {
            resetCallCount++;
            return completer.future;
          },
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Not possible to verify?'));
  await tester.pump();

  await tester.tap(find.text('Reset'));
  await tester.pump();

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.text('Reset'), findsNothing);

  // Tapping Reset or Cancel again while in flight must not call
  // onResetEncryption a second time or close the confirm view.
  await tester.tap(find.text('Cancel'));
  await tester.pump();
  expect(find.text('Reset end-to-end encryption'), findsOneWidget);
  expect(resetCallCount, 1);

  completer.complete(true);
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.byType(CircularProgressIndicator), findsNothing);
}

Future<void> _resetEncryptionReturnsToChooserWhenFalse(
  WidgetTester tester,
) async {
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => VerifyDeviceScreen(
          options: _testOptions(context),
          onResetEncryption: () async => false,
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Not possible to verify?'));
  await tester.pump();
  await tester.tap(find.text('Reset'));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.text('Verify this device'), findsOneWidget);
}

Future<void> _resetEncryptionShowsCompleteAndPops(WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => VerifyDeviceScreen(
            options: _testOptions(context),
            onResetEncryption: () async => true,
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Not possible to verify?'));
  await tester.pump();
  await tester.tap(find.text('Reset'));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.text('Reset complete'), findsOneWidget);

  await tester.tap(find.text('Start chatting'));
  await tester.pumpAndSettle();

  expect(find.text('Reset complete'), findsNothing);
}

void _initialStateTests() {
  testWidgets('VerifyDeviceScreen shows success view immediately when '
      'initialSuccess is true, and pops on Start chatting', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => VerifyDeviceScreen(
              options: _testOptions(context),
              initialSuccess: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Device verified'), findsOneWidget);
    expect(find.text('Verify this device'), findsNothing);

    await tester.tap(find.text('Start chatting'));
    await tester.pumpAndSettle();

    expect(find.text('Device verified'), findsNothing);
  });

  testWidgets(
    'VerifyDeviceScreen shows error view immediately when initialError is '
    'true, and Close returns to the chooser',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => VerifyDeviceScreen(
              options: _testOptions(context),
              initialError: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Verification failed'), findsOneWidget);
      expect(find.text('Verify this device'), findsNothing);

      await tester.tap(find.text('Close'));
      await tester.pump();

      expect(find.text('Verification failed'), findsNothing);
      expect(find.text('Verify this device'), findsOneWidget);
    },
  );
}

void _retryTests() {
  testWidgets(
    'VerifyDeviceScreen reacts to initialSuccess flipping to true on an '
    'already-mounted instance, mirroring BootstrapDialog re-rendering the '
    'same widget after a "Retry automatically" tap resolves asynchronously',
    (tester) async {
      var initialSuccess = false;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => Builder(
              builder: (context) => VerifyDeviceScreen(
                options: _testOptions(context),
                onRetry: () => setState(() => initialSuccess = true),
                initialSuccess: initialSuccess,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Verify this device'), findsOneWidget);
      expect(find.text('Device verified'), findsNothing);

      await tester.tap(find.text('Retry automatically'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Device verified'), findsOneWidget);
      expect(find.text('Verify this device'), findsNothing);
    },
  );

  testWidgets(
    'VerifyDeviceScreen reacts to initialError flipping to true on an '
    'already-mounted instance after a failed retry',
    (tester) async {
      var initialError = false;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => Builder(
              builder: (context) => VerifyDeviceScreen(
                options: _testOptions(context),
                onRetry: () => setState(() => initialError = true),
                initialError: initialError,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Verify this device'), findsOneWidget);
      expect(find.text('Verification failed'), findsNothing);

      await tester.tap(find.text('Retry automatically'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Verification failed'), findsOneWidget);
      expect(find.text('Verify this device'), findsNothing);
    },
  );
}
