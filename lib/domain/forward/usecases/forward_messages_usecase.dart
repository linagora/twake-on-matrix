import 'package:twake_chat/domain/forward/models/forward_result.dart';
import 'package:twake_chat/domain/repository/forward/forward_repository.dart';

class ForwardMessagesUseCase {
  const ForwardMessagesUseCase(this._repository);

  final ForwardRepository _repository;

  /// Rooms not joined or failing are skipped but still count in
  /// [ForwardResult.totalCount]; a room that got only some messages counts in
  /// [ForwardResult.partialCount].
  Future<ForwardResult> execute({
    required List<Map<String, Object?>> messages,
    required List<String> roomIds,
  }) async {
    var successCount = 0;
    var partialCount = 0;
    for (final roomId in roomIds) {
      final sentCount = await _forwardToRoom(roomId, messages);
      if (sentCount == messages.length) {
        successCount++;
      } else if (sentCount > 0) {
        partialCount++;
      }
    }
    return ForwardResult(
      successCount: successCount,
      partialCount: partialCount,
      totalCount: roomIds.length,
    );
  }

  Future<int> _forwardToRoom(
    String roomId,
    List<Map<String, Object?>> messages,
  ) async {
    var sentCount = 0;
    try {
      if (!_repository.isJoined(roomId)) return 0;
      for (final message in messages) {
        await _repository.sendMessage(roomId: roomId, content: message);
        sentCount++;
      }
    } on Exception {
      // A failing room keeps the messages already sent.
    }
    return sentCount;
  }
}
