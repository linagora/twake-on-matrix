import 'package:twake_chat/domain/repository/activity/activity_repository.dart';

/// Reads the main timeline of a room and its threads.
final class MarkRoomReadUseCase {
  const MarkRoomReadUseCase(this._repository);

  final ActivityRepository _repository;

  Future<void> execute(String roomId) => _repository.markRoomRead(roomId);
}
