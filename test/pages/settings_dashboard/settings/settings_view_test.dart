import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings.dart';
import 'package:twake_chat/pages/settings_dashboard/settings/settings_view.dart';
import 'package:twake_chat/presentation/enum/settings/settings_enum.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _FakeClient extends Fake implements Client {
  @override
  String? get userID => '@alice:example.org';
}

class _FakeMatrix extends Fake implements MatrixState {
  @override
  final Client client = _FakeClient();

  @override
  bool get twakeSupported => false;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

/// The notifiers start as the real controller seeds them: nothing loaded.
class _FakeController extends Fake implements SettingsController {
  @override
  final MatrixState matrix = _FakeMatrix();

  @override
  final ValueNotifier<Uri?> avatarUriNotifier = ValueNotifier(null);

  @override
  final ValueNotifier<String?> displayNameNotifier = ValueNotifier(null);

  @override
  final ValueNotifier<bool?> showChatBackupSwitch = ValueNotifier(null);

  @override
  final ValueNotifier<bool> backupStateLoading = ValueNotifier(true);

  @override
  final ValueNotifier<SettingEnum?> optionsSelectNotifier = ValueNotifier(null);

  @override
  final List<SettingEnum> getListSettingItem = [SettingEnum.chatSettings];

  @override
  Client get client => matrix.client;

  @override
  String get displayName => displayNameNotifier.value ?? 'alice';

  @override
  bool optionSelected(SettingEnum settingEnum) => false;

  @override
  void firstRunBootstrapAction([_]) {}

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeController';
}

/// Pumps [SettingsView] over a fake controller and reads what it shows.
class _SettingsViewScreen {
  const _SettingsViewScreen(this.tester, this.controller);

  final WidgetTester tester;
  final _FakeController controller;

  Future<void> pump() async {
    await tester.pumpWidget(
      Provider<MatrixState>.value(
        value: controller.matrix,
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: SettingsView(controller),
        ),
      ),
    );
    await tester.pump();
  }

  String? get avatarName => tester.widget<Avatar>(find.byType(Avatar)).name;

  SwitchListTile get _backupSwitch =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile));

  /// Check ended without a result: shown off, and a tap does nothing.
  void expectUnknownBackupSwitch() {
    expect(_backupSwitch.value, isFalse);
    expect(_backupSwitch.onChanged, isNull);
  }

  /// Backup known to be enabled: shown on, and a tap has an action.
  void expectBackupSwitchOn() {
    expect(_backupSwitch.value, isTrue);
    expect(_backupSwitch.onChanged, isNotNull);
  }
}

void main() {
  late _FakeController controller;

  setUp(() {
    GetIt.instance.registerSingleton(ResponsiveUtils());
    controller = _FakeController();
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('backup state not known yet: a loading tile, no switch', (
    tester,
  ) async {
    await _SettingsViewScreen(tester, controller).pump();

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('backup check ended without a result: the switch is off', (
    tester,
  ) async {
    await _SettingsViewScreen(tester, controller).pump();

    controller.backupStateLoading.value = false;
    await tester.pump();

    _SettingsViewScreen(tester, controller).expectUnknownBackupSwitch();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('backup state known: the switch replaces the loading tile', (
    tester,
  ) async {
    await _SettingsViewScreen(tester, controller).pump();

    controller.showChatBackupSwitch.value = false;
    await tester.pump();

    _SettingsViewScreen(tester, controller).expectBackupSwitchOn();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('profile not loaded yet: the avatar uses the fallback name', (
    tester,
  ) async {
    await _SettingsViewScreen(tester, controller).pump();

    expect(_SettingsViewScreen(tester, controller).avatarName, 'alice');
  });

  testWidgets('display name loaded without a picture: the avatar follows it', (
    tester,
  ) async {
    await _SettingsViewScreen(tester, controller).pump();

    controller.displayNameNotifier.value = 'Alice Martin';
    await tester.pump();

    expect(_SettingsViewScreen(tester, controller).avatarName, 'Alice Martin');
    expect(find.text('Alice Martin'), findsOneWidget);
  });
}
