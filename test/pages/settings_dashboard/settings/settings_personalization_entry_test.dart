import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_personalization/settings_personalization.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/twake_supported_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/theme_builder.dart';

/// A client with no user and no encryption: the profile lookup is skipped and
/// the backup check ends at once (as in `settings_test.dart`).
class _FakeClient extends Fake implements Client {
  @override
  Future<void>? get accountDataLoading => null;

  @override
  bool get encryptionEnabled => false;

  @override
  String? get userID => null;

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
  String? loginType;

  @override
  String? get authUrl => null;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

/// The settings of the app, under the rooms as in the app. The settings pages
/// live right under `/rooms` (`/rooms/folders`, `/rooms/notifications`, …).
Future<void> _pumpSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final client = _FakeClient();
  final router = GoRouter(
    initialLocation: '/rooms/settings',
    errorBuilder: (_, state) =>
        Scaffold(body: Text('no such page: ${state.uri}')),
    routes: [
      GoRoute(
        path: '/rooms',
        builder: (_, _) => const Scaffold(body: Text('rooms')),
        routes: [
          GoRoute(path: 'settings', builder: (_, _) => const Settings()),
          GoRoute(
            path: 'personalization',
            builder: (_, _) => const SettingsPersonalization(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeMatrixClientProvider.overrideWith((ref) => client),
        twakeSupportedProvider.overrideWithValue(false),
      ],
      child: Provider<MatrixState>.value(
        value: _FakeMatrix(client),
        child: ThemeBuilder(
          builder: (context, themeMode, _) => MaterialApp.router(
            routerConfig: router,
            themeMode: themeMode,
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDown(() => GetIt.instance.reset());

  testWidgets('the settings list has a « Personalization » entry', (
    tester,
  ) async {
    await _pumpSettings(tester);

    expect(find.text('Personalization'), findsOneWidget);
  });

  testWidgets(
    'a tap on the entry opens the personalization screen, at 1200 px with '
    'the cards of the five options',
    (tester) async {
      await _pumpSettings(tester);

      await tester.tap(find.text('Personalization'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(find.byType(SettingsPersonalization), findsOneWidget);
      for (final card in const [
        'option-density-comfortable',
        'option-density-compact',
        'option-order-recent',
        'option-order-sections',
        'option-seen-style-ticks',
        'option-seen-style-avatars',
        'option-seen-style-names',
        'option-composer-compact',
        'option-composer-classic',
        'option-align-ownRight',
        'option-align-left',
      ]) {
        expect(
          find.byKey(ValueKey<String>(card)),
          findsOneWidget,
          reason: card,
        );
      }
    },
  );
}
