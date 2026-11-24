abstract class VoiceMessageRepository {
  /// Null when the message shown after [eventId] is not a voice message, when
  /// [eventId] is not one, or at the end of the stored timeline.
  Future<String?> nextVoiceMessageId({
    required String roomId,
    required String eventId,
  });
}
