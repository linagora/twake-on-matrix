import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/utils/platform_infos.dart';

/// One-time migration of local settings persisted under the legacy
/// `chat.fluffy.*` keys (from the FluffyChat-to-Twake package rename) to
/// their `chat.twake.*` equivalents.
abstract class LegacySettingsMigrationManager {
  /// Must run before anything reads [SettingKeys] values, so it is called
  /// once at app startup in `main.dart`.
  static Future<void> migrateLegacySettingKeys() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in legacySettingKeys.entries) {
      _migratePreferenceValue(prefs, newKey: entry.key, legacyKey: entry.value);
    }
    await _migrateAppLockKey();
  }

  static void _migratePreferenceValue(
    SharedPreferences prefs, {
    required String newKey,
    required String legacyKey,
  }) {
    if (prefs.containsKey(newKey) || !prefs.containsKey(legacyKey)) return;
    try {
      _writePreferenceValue(prefs, key: newKey, value: prefs.get(legacyKey));
    } catch (e, s) {
      Logs().w('Unable to migrate legacy setting "$legacyKey"', e, s);
      return;
    }
    prefs.remove(legacyKey);
  }

  static void _writePreferenceValue(
    SharedPreferences prefs, {
    required String key,
    required Object? value,
  }) {
    switch (value) {
      case final String value:
        prefs.setString(key, value);
      case final bool value:
        prefs.setBool(key, value);
      case final int value:
        prefs.setInt(key, value);
      case final double value:
        prefs.setDouble(key, value);
      case final List<String> value:
        prefs.setStringList(key, value);
    }
  }

  /// The app lock PIN lives in [FlutterSecureStorage] on most platforms, but
  /// in [SharedPreferences] on Linux (see `lib/widgets/lock_screen.dart`).
  static Future<void> _migrateAppLockKey() async {
    if (PlatformInfos.isLinux) {
      await _migrateLinuxAppLockKey();
    } else if (PlatformInfos.isMobile) {
      await _migrateMobileAppLockKey();
    }
  }

  static Future<void> _migrateLinuxAppLockKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(SettingKeys.appLockKey) ||
        !prefs.containsKey(legacyAppLockKey)) {
      return;
    }
    final legacyPin = prefs.getString(legacyAppLockKey);
    if (legacyPin == null) return;
    await prefs.setString(SettingKeys.appLockKey, legacyPin);
    await prefs.remove(legacyAppLockKey);
  }

  static Future<void> _migrateMobileAppLockKey() async {
    const secureStorage = FlutterSecureStorage();
    try {
      final existing = await secureStorage.read(key: SettingKeys.appLockKey);
      if (existing != null) return;
      final legacyPin = await secureStorage.read(key: legacyAppLockKey);
      if (legacyPin == null) return;
      await secureStorage.write(key: SettingKeys.appLockKey, value: legacyPin);
      await secureStorage.delete(key: legacyAppLockKey);
    } catch (e, s) {
      Logs().w('Unable to migrate legacy app lock PIN', e, s);
    }
  }
}
