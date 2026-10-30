abstract class ForwardDatasource {
  bool isJoined(String roomId);

  Future<void> sendMessage({
    required String roomId,
    required Map<String, Object?> content,
  });
}
