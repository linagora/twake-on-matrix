import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

/// Where this device keeps the display choices. A stored name this version does not know reads as the default.
class DisplayPreferencesRepository {
  DisplayPreferencesRepository(this._store);

  final Store _store;

  Future<DisplayPreferencesState> load() async {
    const defaults = DisplayPreferencesState();
    return DisplayPreferencesState(
      density: await _read(
        SettingKeys.chatListDensity,
        ChatListDensity.values,
        defaults.density,
      ),
      roomOrder: await _read(
        SettingKeys.roomOrder,
        RoomOrder.values,
        defaults.roomOrder,
      ),
    );
  }

  Future<T> _read<T extends Enum>(
    String key,
    List<T> values,
    T fallback,
  ) async {
    final name = await _store.getItem(key);
    return values.asNameMap()[name] ?? fallback;
  }

  Future<void> save(DisplayPreferencesState preferences) async {
    await _store.setItem(SettingKeys.chatListDensity, preferences.density.name);
    await _store.setItem(SettingKeys.roomOrder, preferences.roomOrder.name);
  }
}
