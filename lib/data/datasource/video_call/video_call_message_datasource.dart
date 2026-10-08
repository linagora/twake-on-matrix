abstract class VideoCallMessageDatasource {
  Future<void> sendCallMessage({
    required String roomId,
    required String url,
    required String body,
  });
}
