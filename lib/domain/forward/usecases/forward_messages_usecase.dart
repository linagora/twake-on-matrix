import 'package:twake_chat/domain/forward/exceptions/forward_exception.dart';
import 'package:twake_chat/domain/forward/models/forward_result.dart';
import 'package:twake_chat/domain/repository/forward/forward_repository.dart';

class ForwardMessagesUseCase {
  const ForwardMessagesUseCase(this._repository);

  final ForwardRepository _repository;

  /// Rooms not joined or failing are skipped but still count in
  /// [ForwardResult.totalCount]; a failing room may get only some messages.
  ///
  /// Throws a [ForwardEmptyContentException] when [messages] is empty.
  Future<ForwardResult> execute({
    required List<Map<String, Object?>> messages,
    required List<String> roomIds,
  }) async {
    if (messages.isEmpty) throw const ForwardEmptyContentException();
    var successCount = 0;
    for (final roomId in roomIds) {
      if (await _forwardToRoom(roomId, messages)) successCount++;
    }
    return ForwardResult(
      successCount: successCount,
      totalCount: roomIds.length,
    );
  }

  Future<bool> _forwardToRoom(
    String roomId,
    List<Map<String, Object?>> messages,
  ) async {
    if (!_repository.isJoined(roomId)) return false;
    try {
      for (final message in messages) {
        await _repository.sendMessage(roomId: roomId, content: message);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
