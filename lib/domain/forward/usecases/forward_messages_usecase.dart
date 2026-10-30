import 'package:twake_chat/domain/forward/exceptions/forward_exception.dart';
import 'package:twake_chat/domain/forward/models/forward_result.dart';
import 'package:twake_chat/domain/repository/forward/forward_repository.dart';

class ForwardMessagesUseCase {
  const ForwardMessagesUseCase(this._repository);

  final ForwardRepository _repository;

  /// Throws a [ForwardEmptyContentException] when [messages] is empty.
  Future<ForwardResult> execute({
    required List<Map<String, Object?>> messages,
    required List<String> roomIds,
  }) async {
    if (messages.isEmpty) throw const ForwardEmptyContentException();
    var successCount = 0;
    for (final roomId in roomIds) {
      if (!_repository.isJoined(roomId)) continue;
      try {
        for (final message in messages) {
          await _repository.sendMessage(roomId: roomId, content: message);
        }
      } catch (_) {
        continue;
      }
      successCount++;
    }
    return ForwardResult(
      successCount: successCount,
      totalCount: roomIds.length,
    );
  }
}
