import 'package:shared_preferences/shared_preferences.dart';

/// Persists the unsent message draft of a room across app sessions.
///
/// Centralizes the `draft_<roomId>` key so the format lives in a single place
/// instead of being duplicated at every call site.
class RoomDraftStorage {
  const RoomDraftStorage();

  String _keyOf(String roomId) => 'draft_$roomId';

  Future<String?> read(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOf(roomId));
  }

  Future<void> save(String roomId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOf(roomId), text);
  }

  Future<void> remove(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOf(roomId));
  }
}
