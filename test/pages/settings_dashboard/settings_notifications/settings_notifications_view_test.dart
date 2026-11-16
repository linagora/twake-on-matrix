import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_notifications/settings_notifications.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_notifications/settings_notifications_view.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

class _FakeClient extends Fake implements Client {
  _FakeClient({required this.allPushNotificationsMuted});

  @override
  final bool allPushNotificationsMuted;

  @override
  final CachedStreamController<BasicEvent> onAccountData =
      CachedStreamController();
}

class _FakeController extends Fake implements SettingsNotificationsController {
  @override
  bool get showWebPushTile => false;

  @override
  bool get showEncryptedPreviewsTile => false;

  @override
  bool? getNotificationSetting(NotificationSettingsItem item) => true;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeController';
}

void main() {
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpView(
    WidgetTester tester, {
    required bool muted,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          matrixClientProvider.overrideWithValue(
            _FakeClient(allPushNotificationsMuted: muted),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          locale: locale,
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: SettingsNotificationsView(_FakeController()),
        ),
      ),
    );
    await tester.pump();
  }

  Finder masterSwitchFinder() => find.byType(SwitchListTile).first;

  SwitchListTile masterSwitch(WidgetTester tester) =>
      tester.widget<SwitchListTile>(masterSwitchFinder());

  Finder textInMasterSwitch(String text) =>
      find.descendant(of: masterSwitchFinder(), matching: find.text(text));

  testWidgets('notifications on: the switch is on, labelled Notifications', (
    tester,
  ) async {
    await pumpView(tester, muted: false);

    expect(masterSwitch(tester).value, isTrue);
    expect(
      textInMasterSwitch(lookupL10n(const Locale('en')).notifications),
      findsOneWidget,
    );
  });

  testWidgets(
    'notifications muted: the switch is off, the label does not change',
    (tester) async {
      await pumpView(tester, muted: true);

      expect(masterSwitch(tester).value, isFalse);
      expect(
        textInMasterSwitch(lookupL10n(const Locale('en')).notifications),
        findsOneWidget,
      );
      expect(find.byType(SwitchListTile), findsOneWidget);
    },
  );

  testWidgets('in Spanish, the switch is labelled with the translated key', (
    tester,
  ) async {
    const es = Locale('es');
    await pumpView(tester, muted: false, locale: es);

    expect(masterSwitch(tester).value, isTrue);
    expect(textInMasterSwitch(lookupL10n(es).notifications), findsOneWidget);
  });
}
