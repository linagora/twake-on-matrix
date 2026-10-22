import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_actions.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_item.dart';

void main() {
  const setLabel = 'Set profile avatar';
  const changeLabel = 'Change profile avatar';

  Future<void> pumpItem(WidgetTester tester, ValueNotifier<bool> hasAvatar) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: SettingsProfileContextMenuItem(
            action: SettingsProfileContextMenuActions.edit,
            profileListenable: hasAvatar,
            hasAvatar: () => hasAvatar.value,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('edit item reads "Set" when there is no avatar', (tester) async {
    await pumpItem(tester, ValueNotifier(false));

    expect(find.text(setLabel), findsOneWidget);
  });

  testWidgets('edit item follows the avatar as the profile changes', (
    tester,
  ) async {
    final hasAvatar = ValueNotifier(false);
    await pumpItem(tester, hasAvatar);
    expect(find.text(setLabel), findsOneWidget);

    hasAvatar.value = true;
    await tester.pump();
    expect(find.text(changeLabel), findsOneWidget);

    hasAvatar.value = false;
    await tester.pump();
    expect(find.text(setLabel), findsOneWidget);
  });
}
