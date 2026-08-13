import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/utils/manager/legacy_settings_migration_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LegacySettingsMigrationManager.migrateLegacySettingKeys', () {
    test('copies a legacy string value to its new key and removes the '
        'legacy key', () async {
      SharedPreferences.setMockInitialValues({
        'chat.fluffy.wallpaper': '/path/to/wallpaper.png',
      });

      await LegacySettingsMigrationManager.migrateLegacySettingKeys();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SettingKeys.wallpaper), '/path/to/wallpaper.png');
      expect(prefs.containsKey('chat.fluffy.wallpaper'), isFalse);
    });

    test('copies a legacy bool value to its new key', () async {
      SharedPreferences.setMockInitialValues({'chat.fluffy.renderHtml': false});

      await LegacySettingsMigrationManager.migrateLegacySettingKeys();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingKeys.renderHtml), isFalse);
      expect(prefs.containsKey('chat.fluffy.renderHtml'), isFalse);
    });

    test(
      'does not overwrite an existing new-key value with the legacy one',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingKeys.wallpaper: '/already/migrated.png',
          'chat.fluffy.wallpaper': '/stale/legacy.png',
        });

        await LegacySettingsMigrationManager.migrateLegacySettingKeys();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(SettingKeys.wallpaper), '/already/migrated.png');
      },
    );

    test('is a no-op when neither key is present', () async {
      SharedPreferences.setMockInitialValues({});

      await LegacySettingsMigrationManager.migrateLegacySettingKeys();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(SettingKeys.wallpaper), isFalse);
    });

    test('migrates every mapped legacy key present in storage', () async {
      SharedPreferences.setMockInitialValues({
        for (final entry in legacySettingKeys.entries) entry.value: true,
      });

      await LegacySettingsMigrationManager.migrateLegacySettingKeys();

      final prefs = await SharedPreferences.getInstance();
      for (final entry in legacySettingKeys.entries) {
        expect(
          prefs.containsKey(entry.key),
          isTrue,
          reason: '${entry.key} should have been migrated',
        );
        expect(prefs.containsKey(entry.value), isFalse);
      }
    });
  });
}
