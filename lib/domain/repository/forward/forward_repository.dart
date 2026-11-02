abstract class ForwardRepository {
  bool isJoined(String roomId);

  Future<void> sendMessage({
    required String roomId,
    required Map<String, Object?> content,
  });
}
