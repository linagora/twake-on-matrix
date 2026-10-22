import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_actions.dart';

void main() {
  Future<String> titleOf(
    WidgetTester tester,
    SettingsProfileContextMenuActions action, {
    required bool hasAvatar,
  }) async {
    late String title;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Builder(
          builder: (context) {
            title = action.getTitle(context, hasAvatar: hasAvatar);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return title;
  }

  for (final (hasAvatar, expected) in [
    (false, 'Set profile avatar'),
    (true, 'Change profile avatar'),
  ]) {
    testWidgets('edit action reads "$expected" when hasAvatar is $hasAvatar', (
      tester,
    ) async {
      expect(
        await titleOf(
          tester,
          SettingsProfileContextMenuActions.edit,
          hasAvatar: hasAvatar,
        ),
        expected,
      );
    });
  }
}
