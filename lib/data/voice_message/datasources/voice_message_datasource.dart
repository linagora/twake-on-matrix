abstract class VoiceMessageDatasource {
  Future<String?> nextVoiceMessageId({
    required String roomId,
    required String eventId,
  });
}
