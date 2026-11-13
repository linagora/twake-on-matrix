import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_notifications/settings_notifications.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_notifications/settings_notifications_view.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _FakeClient extends Fake implements Client {
  _FakeClient({required this.allPushNotificationsMuted});

  @override
  final bool allPushNotificationsMuted;

  @override
  final CachedStreamController<BasicEvent> onAccountData =
      CachedStreamController();
}

class _FakeMatrix extends Fake implements MatrixState {
  _FakeMatrix(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
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

  Future<void> pumpView(WidgetTester tester, {required bool muted}) {
    return tester.pumpWidget(
      Provider<MatrixState>.value(
        value: _FakeMatrix(_FakeClient(allPushNotificationsMuted: muted)),
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: SettingsNotificationsView(_FakeController()),
        ),
      ),
    );
  }

  SwitchListTile masterSwitch(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first);

  testWidgets('notifications on: the switch is on and reads enabled', (
    tester,
  ) async {
    await pumpView(tester, muted: false);
    await tester.pump();

    expect(masterSwitch(tester).value, isTrue);
    expect(
      find.descendant(
        of: find.byType(SwitchListTile).first,
        matching: find.text('Notifications enabled'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('notifications muted: the switch is off and reads disabled', (
    tester,
  ) async {
    await pumpView(tester, muted: true);
    await tester.pump();

    expect(masterSwitch(tester).value, isFalse);
    expect(
      find.descendant(
        of: find.byType(SwitchListTile).first,
        matching: find.text('Notifications disabled'),
      ),
      findsOneWidget,
    );
    expect(find.byType(SwitchListTile), findsOneWidget);
  });
}
