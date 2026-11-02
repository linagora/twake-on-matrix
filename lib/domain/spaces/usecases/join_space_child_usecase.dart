import 'package:twake_chat/domain/repository/spaces/space_repository.dart';

class JoinSpaceChildUseCase {
  const JoinSpaceChildUseCase(this._repository);

  final SpaceRepository _repository;

  /// Throws a `SpaceJoinFailedException`.
  Future<void> execute(String roomId, {List<String> via = const []}) =>
      _repository.joinRoom(roomId, via: via);
}
