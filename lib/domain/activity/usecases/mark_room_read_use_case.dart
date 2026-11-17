import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

/// Reads the main timeline of a room and its threads.
final class MarkRoomReadUseCase {
  const MarkRoomReadUseCase(this._repository);

  final ActivityRepository _repository;

  Future<void> execute(String roomId) async {
    try {
      await _repository.markRoomRead(roomId);
    } on Exception catch (e, s) {
      Logs().w('Unable to mark the room as read', e, s);
      rethrow;
    }
  }
}
