import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_controller.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_state.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

class _FakeController extends SettingsContactsVisibilityController {
  _FakeController({this.failUpdate = false});

  final bool failUpdate;
  final List<SettingsContactsVisibilityEnum> selected = [];

  @override
  Future<SettingsContactsVisibilityState> build() async =>
      const SettingsContactsVisibilityState(
        visibility: SettingsContactsVisibilityEnum.public,
        visibleFields: [VisibleEnum.email],
      );

  @override
  Future<void> selectVisibility(SettingsContactsVisibilityEnum option) async {
    selected.add(option);
    if (failUpdate) throw UpdateUserInfoVisibilityException(Exception('mock'));
  }
}

void main() {
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDown(GetIt.instance.reset);

  Future<void> pumpScreen(WidgetTester tester, _FakeController controller) =>
      tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer.test(
            retry: (_, _) => null,
            overrides: [
              settingsContactsVisibilityControllerProvider.overrideWith(
                () => controller,
              ),
            ],
          ),
          child: MaterialApp(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: const SettingsContactsVisibility(),
          ),
        ),
      );

  Finder option(SettingsContactsVisibilityEnum option) =>
      find.byKey(Key('visibility_option_${option.name}'));

  testWidgets('tapping the selected option sends no update', (tester) async {
    final controller = _FakeController();
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(option(SettingsContactsVisibilityEnum.public));
    await tester.pumpAndSettle();

    expect(controller.selected, isEmpty);
  });

  testWidgets('a failed update shows a snackbar and closes the dialog', (
    tester,
  ) async {
    final controller = _FakeController(failUpdate: true);
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(option(SettingsContactsVisibilityEnum.private));
    await tester.pumpAndSettle();

    expect(controller.selected, [SettingsContactsVisibilityEnum.private]);
    expect(find.text('Failed to change contacts visibility'), findsOneWidget);
    expect(find.text('Loading...'), findsNothing);
    expect(
      find.byKey(const Key('visibility_option_selected_public')),
      findsOneWidget,
    );
  });
}
