import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_actions.dart';

void main() {
  const setLabel = 'Set profile avatar';
  const changeLabel = 'Change profile avatar';
  const removeLabel = 'Remove your avatar';

  Future<void> pumpMenu(
    WidgetTester tester, {
    required bool hasAvatar,
    ValueChanged<SettingsProfileContextMenuActions>? onAction,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: IntrinsicWidth(
            child: SettingsProfileContextMenu(
              hasAvatar: hasAvatar,
              onAction: onAction ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('without an avatar, offers only to set one', (tester) async {
    await pumpMenu(tester, hasAvatar: false);

    expect(find.text(setLabel), findsOneWidget);
    expect(find.text(removeLabel), findsNothing);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('with an avatar, offers to change or remove it', (tester) async {
    await pumpMenu(tester, hasAvatar: true);

    expect(find.text(changeLabel), findsOneWidget);
    expect(find.text(removeLabel), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('tapping an item reports its action', (tester) async {
    final tapped = <SettingsProfileContextMenuActions>[];
    await pumpMenu(tester, hasAvatar: true, onAction: tapped.add);

    await tester.tap(find.text(removeLabel));

    expect(tapped, [SettingsProfileContextMenuActions.delete]);
  });
}
