abstract class VideoCallMessageDatasource {
  bool isJoined(String roomId);

  Future<void> sendCallMessage({
    required String roomId,
    required String url,
    required String body,
  });
}
