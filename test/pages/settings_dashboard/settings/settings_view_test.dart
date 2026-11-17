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

void main() {
  late _FakeController controller;

  setUp(() {
    GetIt.instance.registerSingleton(ResponsiveUtils());
    controller = _FakeController();
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpView(WidgetTester tester) async {
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

  String? avatarName(WidgetTester tester) =>
      tester.widget<Avatar>(find.byType(Avatar)).name;

  testWidgets('backup state not known yet: a loading tile, no switch', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('backup state known: the switch replaces the loading tile', (
    tester,
  ) async {
    await pumpView(tester);

    controller.showChatBackupSwitch.value = false;
    await tester.pump();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('profile not loaded yet: the avatar uses the fallback name', (
    tester,
  ) async {
    await pumpView(tester);

    expect(avatarName(tester), 'alice');
  });

  testWidgets('display name loaded without a picture: the avatar follows it', (
    tester,
  ) async {
    await pumpView(tester);

    controller.displayNameNotifier.value = 'Alice Martin';
    await tester.pump();

    expect(avatarName(tester), 'Alice Martin');
    expect(find.text('Alice Martin'), findsOneWidget);
  });
}
