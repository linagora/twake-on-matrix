import 'package:shared_preferences/shared_preferences.dart';

/// Persists the unsent message draft of a room across app sessions.
///
/// A thread has its own draft, keyed `draft_<roomId>|<rootId>`.
///
/// Centralizes the `draft_<roomId>` key so the format lives in a single place
/// instead of being duplicated at every call site.
class RoomDraftStorage {
  const RoomDraftStorage();

  String _keyOf(String roomId, String? threadRootId) =>
      threadRootId == null ? 'draft_$roomId' : 'draft_$roomId|$threadRootId';

  Future<String?> read(String roomId, {String? threadRootId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOf(roomId, threadRootId));
  }

  Future<void> save(String roomId, String text, {String? threadRootId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOf(roomId, threadRootId), text);
  }

  Future<void> remove(String roomId, {String? threadRootId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOf(roomId, threadRootId));
  }
}
