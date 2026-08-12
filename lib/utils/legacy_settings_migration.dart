import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/utils/platform_infos.dart';

/// One-time migration of local settings persisted under the legacy
/// `chat.fluffy.*` keys (from the FluffyChat-to-Twake package rename) to
/// their `chat.twake.*` equivalents.
///
/// Must run before anything reads [SettingKeys] values, so it is called
/// once at app startup in `main.dart`.
Future<void> migrateLegacySettingKeys() async {
  final prefs = await SharedPreferences.getInstance();
  for (final entry in legacySettingKeys.entries) {
    _migratePreferenceValue(prefs, newKey: entry.key, legacyKey: entry.value);
  }
  await _migrateAppLockKey(prefs);
}

void _migratePreferenceValue(
  SharedPreferences prefs, {
  required String newKey,
  required String legacyKey,
}) {
  if (prefs.containsKey(newKey) || !prefs.containsKey(legacyKey)) return;
  final legacyValue = prefs.get(legacyKey);
  try {
    switch (legacyValue) {
      case final String value:
        prefs.setString(newKey, value);
      case final bool value:
        prefs.setBool(newKey, value);
      case final int value:
        prefs.setInt(newKey, value);
      case final double value:
        prefs.setDouble(newKey, value);
      case final List<String> value:
        prefs.setStringList(newKey, value);
    }
  } catch (e, s) {
    Logs().w('Unable to migrate legacy setting "$legacyKey"', e, s);
    return;
  }
  prefs.remove(legacyKey);
}

/// The app lock PIN lives in [FlutterSecureStorage] on most platforms, but
/// in [SharedPreferences] on Linux (see `lib/widgets/lock_screen.dart`).
Future<void> _migrateAppLockKey(SharedPreferences prefs) async {
  if (!PlatformInfos.isMobile && !kIsWeb && !PlatformInfos.isLinux) return;

  if (PlatformInfos.isLinux) {
    if (prefs.containsKey(SettingKeys.appLockKey) ||
        !prefs.containsKey(legacyAppLockKey)) {
      return;
    }
    final legacyPin = prefs.getString(legacyAppLockKey);
    if (legacyPin == null) return;
    await prefs.setString(SettingKeys.appLockKey, legacyPin);
    await prefs.remove(legacyAppLockKey);
    return;
  }

  if (!PlatformInfos.isMobile) return;
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
