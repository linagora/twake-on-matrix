import 'package:twake_chat/domain/voice_message/entities/shown_message.dart';
import 'package:twake_chat/domain/voice_message/exceptions/voice_message_exception.dart';
import 'package:twake_chat/domain/voice_message/repositories/voice_message_repository.dart';

/// The voice message to play once [eventId] ends, if the next message is one.
final class FindNextVoiceMessageUseCase {
  const FindNextVoiceMessageUseCase(this._repository);

  final VoiceMessageRepository _repository;

  /// [shown] is what the screen shows, oldest first. The stored timeline is
  /// read only when it does not show [eventId].
  Future<String?> execute({
    required String roomId,
    required String eventId,
    String? threadRootId,
    List<ShownMessage> shown = const [],
  }) async {
    final index = shown.indexWhere((message) => message.eventId == eventId);
    if (index >= 0) return _nextShown(shown, index);
    try {
      return await _repository.nextVoiceMessageId(
        roomId: roomId,
        eventId: eventId,
        threadRootId: threadRootId,
      );
    } on Exception catch (e, s) {
      Error.throwWithStackTrace(FindNextVoiceMessageException(e), s);
    }
  }

  String? _nextShown(List<ShownMessage> shown, int index) {
    if (!shown[index].isVoiceMessage || index + 1 >= shown.length) return null;
    final next = shown[index + 1];
    return next.isVoiceMessage ? next.eventId : null;
  }
}
