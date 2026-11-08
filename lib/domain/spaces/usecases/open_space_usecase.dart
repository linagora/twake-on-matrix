import 'package:twake_chat/domain/repository/spaces/space_repository.dart';

class OpenSpaceUseCase {
  const OpenSpaceUseCase(this._repository);

  final SpaceRepository _repository;

  /// Opening its home reads a space: it has no conversation to read.
  Future<void> execute(String roomId) => _repository.open(roomId);
}
