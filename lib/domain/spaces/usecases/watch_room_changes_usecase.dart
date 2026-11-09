import 'package:twake_chat/domain/repository/spaces/space_repository.dart';

class WatchRoomChangesUseCase {
  const WatchRoomChangesUseCase(this._repository);

  final SpaceRepository _repository;

  /// Ticks when the rooms change.
  Stream<int> execute() => _repository.watchRoomChanges();
}
