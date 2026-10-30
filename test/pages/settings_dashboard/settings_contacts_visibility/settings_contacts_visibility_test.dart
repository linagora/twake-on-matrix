import 'dart:async';

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

const _loaded = SettingsContactsVisibilityState(
  visibility: SettingsContactsVisibilityEnum.public,
  visibleFields: [VisibleEnum.email],
);

class _FakeController extends SettingsContactsVisibilityController {
  _FakeController({
    this.failUpdate = false,
    Completer<SettingsContactsVisibilityState>? pendingLoad,
    this.onSelect,
  }) : _pendingLoad = pendingLoad;

  final bool failUpdate;
  Completer<SettingsContactsVisibilityState>? _pendingLoad;
  final Future<void> Function(_FakeController controller)? onSelect;
  final List<SettingsContactsVisibilityEnum> selected = [];
  final List<VisibleEnum> toggled = [];

  @override
  Future<SettingsContactsVisibilityState> build() async =>
      _pendingLoad?.future ?? _loaded;

  @override
  Future<void> selectVisibility(SettingsContactsVisibilityEnum option) async {
    selected.add(option);
    await onSelect?.call(this);
    if (failUpdate) throw UpdateUserInfoVisibilityException(Exception('mock'));
  }

  @override
  Future<void> toggleVisibleField(VisibleEnum field) async {
    toggled.add(field);
    if (failUpdate) throw UpdateUserInfoVisibilityException(Exception('mock'));
  }

  void reloadWith(Completer<SettingsContactsVisibilityState> load) {
    _pendingLoad = load;
    ref.invalidateSelf();
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

  final loadingDialog = find.text('Loading...');

  Future<void> pumpDialogTransition(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 1));

  testWidgets('shows the loading dialog until the visibility is loaded', (
    tester,
  ) async {
    final load = Completer<SettingsContactsVisibilityState>();
    await pumpScreen(tester, _FakeController(pendingLoad: load));
    await pumpDialogTransition(tester);

    expect(loadingDialog, findsOneWidget);

    load.complete(_loaded);
    await tester.pumpAndSettle();

    expect(loadingDialog, findsNothing);
    expect(
      find.byKey(const Key('visibility_option_selected_public')),
      findsOneWidget,
    );
  });

  testWidgets('a failed load shows a snackbar and closes the dialog', (
    tester,
  ) async {
    final load = Completer<SettingsContactsVisibilityState>();
    await pumpScreen(tester, _FakeController(pendingLoad: load));
    await pumpDialogTransition(tester);

    load.completeError(GetUserInfoVisibilityException(Exception('mock')));
    await tester.pumpAndSettle();

    expect(loadingDialog, findsNothing);
    expect(find.text('Failed to get contacts visibility'), findsOneWidget);
  });

  testWidgets('a reload during an update shows a single loading dialog', (
    tester,
  ) async {
    final update = Completer<void>();
    final reload = Completer<SettingsContactsVisibilityState>();
    final controller = _FakeController(
      onSelect: (controller) {
        controller.reloadWith(reload);
        return update.future;
      },
    );
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(option(SettingsContactsVisibilityEnum.private));
    await pumpDialogTransition(tester);

    expect(loadingDialog, findsOneWidget);

    reload.complete(_loaded);
    await pumpDialogTransition(tester);

    expect(loadingDialog, findsOneWidget);

    update.complete();
    await tester.pumpAndSettle();

    expect(loadingDialog, findsNothing);
    expect(option(SettingsContactsVisibilityEnum.private), findsOneWidget);
  });

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

  testWidgets('a failed field update shows a snackbar and closes the dialog', (
    tester,
  ) async {
    final controller = _FakeController(failUpdate: true);
    await pumpScreen(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('visible_field_option_phone')));
    await tester.pumpAndSettle();

    expect(controller.toggled, [VisibleEnum.phone]);
    expect(find.text('Failed to change contacts visibility'), findsOneWidget);
    expect(loadingDialog, findsNothing);
  });
}
