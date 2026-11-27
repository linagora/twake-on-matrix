import 'dart:convert';

import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_search_style.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

/// Where this device keeps the display choices and the personalization steps
/// it has seen. A stored name this version does not know reads as the default.
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
      searchStyle: await _read(
        SettingKeys.searchStyle,
        ChatListSearchStyle.values,
        defaults.searchStyle,
      ),
      seenStyle: await _read(
        SettingKeys.seenStyle,
        SeenStyle.values,
        defaults.seenStyle,
      ),
      composerStyle: await _read(
        SettingKeys.composerStyle,
        ComposerStyle.values,
        defaults.composerStyle,
      ),
      bubbleAlign: await _read(
        SettingKeys.bubbleAlign,
        BubbleAlign.values,
        defaults.bubbleAlign,
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
    await _store.setItem(SettingKeys.searchStyle, preferences.searchStyle.name);
    await _store.setItem(SettingKeys.seenStyle, preferences.seenStyle.name);
    await _store.setItem(
      SettingKeys.composerStyle,
      preferences.composerStyle.name,
    );
    await _store.setItem(SettingKeys.bubbleAlign, preferences.bubbleAlign.name);
  }

  /// The ids of the steps seen; ids of a newer version are kept.
  Future<Set<String>> loadSeenSteps() async => parseSeenSteps(
    await _store.getItem(SettingKeys.personalizedSteps),
  ).toSet();

  Future<void> saveSeenSteps(Set<String> steps) =>
      _store.setItem(SettingKeys.personalizedSteps, jsonEncode(steps.toList()));
}
