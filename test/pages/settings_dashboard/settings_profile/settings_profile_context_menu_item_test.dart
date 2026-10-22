import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_actions.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_item.dart';

void main() {
  const setLabel = 'Set profile avatar';
  const changeLabel = 'Change profile avatar';

  Profile profile({Uri? avatarUrl}) => Profile(
    userId: '@alice:example.com',
    displayName: 'Alice',
    avatarUrl: avatarUrl,
  );

  Future<void> pumpItem(
    WidgetTester tester,
    ValueNotifier<Profile?> currentProfile,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: SettingsProfileContextMenuItem(
            action: SettingsProfileContextMenuActions.edit,
            currentProfile: currentProfile,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('edit item reads "Set" while the profile is not loaded', (
    tester,
  ) async {
    await pumpItem(tester, ValueNotifier(null));

    expect(find.text(setLabel), findsOneWidget);
  });

  testWidgets('edit item follows the avatar as the profile changes', (
    tester,
  ) async {
    final currentProfile = ValueNotifier<Profile?>(profile());
    await pumpItem(tester, currentProfile);
    expect(find.text(setLabel), findsOneWidget);

    currentProfile.value = profile(avatarUrl: Uri.parse('mxc://example.com/a'));
    await tester.pump();
    expect(find.text(changeLabel), findsOneWidget);

    currentProfile.value = profile();
    await tester.pump();
    expect(find.text(setLabel), findsOneWidget);
  });
}
