import 'package:twake_chat/domain/voice_message/exceptions/voice_message_exception.dart';
import 'package:twake_chat/domain/voice_message/repositories/voice_message_repository.dart';

/// The voice message to play once [eventId] ends, if the next message is one.
final class FindNextVoiceMessageUseCase {
  const FindNextVoiceMessageUseCase(this._repository);

  final VoiceMessageRepository _repository;

  Future<String?> execute({
    required String roomId,
    required String eventId,
  }) async {
    try {
      return await _repository.nextVoiceMessageId(
        roomId: roomId,
        eventId: eventId,
      );
    } catch (e, s) {
      Error.throwWithStackTrace(FindNextVoiceMessageException(e), s);
    }
  }
}
